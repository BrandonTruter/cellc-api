# This is a typical config file for a new integration

TenbewDoiApi::Application.config.QQ_CONFIG = YAML.load_file("#{Rails.root}/config/qq.yml")

sflog = Logger.new("#{Rails.root}/log/#{Rails.env}_qq.log")
sflog.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%Y/%m/%d %H:%M:%S')}, #{Socket.gethostname}, #{severity}, #{msg}\n"
end

::QQ = sflog
