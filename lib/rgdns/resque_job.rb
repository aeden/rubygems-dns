module Rgdns
  class ResqueJob
    include Rgdns::Loggable

    def log_and_reraise( e )
      logger.error "#{e.class} #{e.message}"
      e.backtrace.each { |b| logger.debug b }
      raise e
    end
  end
end
