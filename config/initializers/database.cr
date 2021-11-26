require "jennifer"
require "jennifer/adapter/postgres"

Jennifer::Config.configure do |conf|
  conf.from_uri(ENV.fetch("DATABASE_URL"))
  conf.logger.level = APP_ENV == "development" ? Log::Severity::Debug : Log::Severity::Error
end

Log.setup "db", :debug, Log::IOBackend.new(formatter: Jennifer::Adapter::DBFormatter)
