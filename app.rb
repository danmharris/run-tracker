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
      r.get 'new' do
        view('runs/new')
      end

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
    end
  end
end
