require 'gpx'
require 'roda'
require 'tilt'
require_relative 'models'

class App < Roda
  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.img_src :self
    csp.style_src :self, 'unpkg.com'
    csp.script_src :self, 'unpkg.com', [:sha256, 'ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM=']
    csp.connect_src :self, 'tiles.openfreemap.org'
    csp.worker_src 'blob:'
    csp.font_src :self
    csp.form_action :self
    csp.base_uri :none
    csp.frame_ancestors :none
    csp.block_all_mixed_content
  end

  plugin :default_headers,
         'Content-Type' => 'text/html',
         'X-Frame-Options' => 'deny',
         'X-Content-Type-Options' => 'nosniff'

  plugin :assets, css: 'main.css', js: 'main.js'
  plugin :common_logger, $stdout
  plugin :content_for
  plugin :json
  plugin :relative_path
  plugin :render
  plugin :route_csrf
  plugin :sessions, secret: ENV['SECRET_KEY']
  plugin :typecast_params
  alias tp typecast_params

  plugin :exception_page
  plugin :error_handler do |e|
    next exception_page(e, assets: true) if ENV['RACK_ENV'] == 'development'
  end

  def data_dir
    ENV.fetch('DATA_DIR', FileUtils.pwd)
  end

  def runs_dir
    File.join(data_dir, 'runs')
  end

  def format_seconds(time)
    minutes = (time / 60).floor
    seconds = (time % 60).floor

    "#{minutes}:#{format('%.2d', seconds)}"
  end

  route do |r|
    r.exception_page_assets
    r.assets
    check_csrf!

    r.root do
      @runs = Run.order(:timestamp).reverse.all
      view('runs/index')
    end

    r.on 'runs' do
      r.is do
        r.get do
          @runs = Run.order(:timestamp).reverse.all
          view('runs/index')
        end

        r.post do
          tempfile = tp.file('file')[:tempfile]
          gpx = GPX::GPXFile.new(gpx_file: tempfile)
          uuid = SecureRandom.uuid
          Run.create(
            uuid: uuid,
            timestamp: gpx.tracks.first.points.first.time,
            distance: gpx.distance,
            duration: gpx.duration
          )
          FileUtils.mv(tempfile.path, File.join(runs_dir, "#{uuid}.gpx"))
          r.redirect("/runs/#{uuid}")
        end
      end

      r.get 'new' do
        view('runs/new')
      end

      r.on String do |id|
        next unless @run = Run.first(uuid: id)

        gpx = GPX::GPXFile.new(gpx_file: File.join(runs_dir, "#{id}.gpx"))

        r.get 'geojson' do
          features = gpx.tracks.map do |track|
            coordinates = track.points.map { [_1.lon, _1.lat] }

            {
              type: 'Feature',
              geometry: { type: 'LineString', coordinates: coordinates }
            }
          end

          {
            type: 'FeatureCollection',
            features: features
          }
        end

        r.get true do
          @bounds = gpx.tracks.first.bounds
          @geojson_url = "#{r.path}/geojson"

          view('runs/show')
        end
      end
    end
  end
end
