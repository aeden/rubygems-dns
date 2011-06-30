require 'rgdns/logger'
module Rgdns
  module Loggable
    def logger
      Rgdns::Logger.init
      Logging::Logger[Rgdns]
    end
  end
end
