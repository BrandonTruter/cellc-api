# This is a typical config file for a new integration

TenbewDoiApi::Application.config.CELLC_CONFIG = YAML.load_file("#{Rails.root}/config/cellc.yml")

sflog = Logger.new("#{Rails.root}/log/#{Rails.env}_cellc.log")
sflog.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%Y/%m/%d %H:%M:%S')}, #{Socket.gethostname}, #{severity}, #{msg}\n"
end

::CELLC = sflog
