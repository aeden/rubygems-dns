module Rgdns::Webhook
  class Logger
    include Rgdns::Loggable

    def initialize( app, opts = {} )
      @app = app
      @level = opts[:level] || :info
      @logger = self.logger
    end

    def call( env )
      env['rack.logger'] = self.logger
      @app.call( env )
    end
  end
end
