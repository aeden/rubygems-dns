module Rgdns::Monitor
  # A sinatra app for monitoring the status of the Rgdns system

  class App < Sinatra::Base
    include Rgdns::Loggable

    def initialize(app = nil, options = {})
      @app = app
      super(@app)
    end

    get '/' do
      "Nothing here"
    end
  end
end
