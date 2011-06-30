module Rgdns
  class Logger
    def self.init
      unless @initialized
        layout   = Logging::Layouts::Pattern.new(:pattern => "%5l %c : %m")
        options = {
          :logopt => Syslog::Constants::LOG_CONS | Syslog::Constants::LOG_PID, 
          :facility => Syslog::Constants::LOG_LOCAL0,
          :layout => layout
        }
        logger = Logging::Logger[Rgdns]
        appender = Logging::Appenders::Syslog.new('Rubygems-DNS', options)
        logger.add_appenders(appender)
        @initialized = true
      end
      return @initialized
    end
  end
end
