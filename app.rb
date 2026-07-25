require 'gpx'
require 'roda'
require 'tilt'

class App < Roda
  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.img_src :self
    csp.style_src :self
    csp.script_src :self
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

  plugin :common_logger, $stdout
  plugin :content_for
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

  route do |r|
    r.exception_page_assets
    check_csrf!

    r.root do
      view('index')
    end

    r.on 'runs' do
      r.is do
        r.get do
          @runs = Dir["#{runs_dir}/*"].map { File.basename(_1).sub(/[.]gpx$/, '') }
          view('runs/index')
        end

        r.post do
          tempfile = tp.file('file')[:tempfile]
          uuid = SecureRandom.uuid
          FileUtils.mv(tempfile.path, File.join(runs_dir, "#{uuid}.gpx"))
          r.redirect('/runs')
        end
      end

      r.get 'new' do
        view('runs/new')
      end

      r.on String do |id|
        r.get do
          @nonce = SecureRandom.uuid
          content_security_policy do |csp|
            csp.add_style_src('unpkg.com', [:nonce, @nonce])
            csp.add_script_src('unpkg.com', [:nonce, @nonce], [:sha256, 'ZswfTY7H35rbv8WC7NXBoiC7WNu86vSzCDChNWwZZDM='])
            csp.add_connect_src('tiles.openfreemap.org')
            csp.add_worker_src('blob:')
          end

          gpx = GPX::GPXFile.new(gpx_file: File.join(runs_dir, "#{id}.gpx"))
          @distance = gpx.distance
          @time = gpx.duration / 60

          features = gpx.tracks.map do |track|
            coordinates = track.points.map { [_1.lon, _1.lat] }

            {
              type: 'Feature',
              geometry: { type: 'LineString', coordinates: coordinates }
            }
          end

          @start = gpx.tracks.first.points.first.then { [_1.lon, _1.lat] }.to_json
          @geojson = {
            type: 'FeatureCollection',
            features: features
          }.to_json

          view('runs/show')
        end
      end
    end
  end
end
