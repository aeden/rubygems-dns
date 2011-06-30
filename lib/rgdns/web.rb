module Rgdns
  class Web
    def initialize( root = nil )
      @root = File.expand_path( root ) if root
    end

    def app
      Rack::Builder.new do
        use Rgdns::Webhook::Logger, :level => :debug
        use Rack::CommonLogger

        map "/" do
          run Rgdns::Monitor::App.new 
        end

        map "/webhook" do
          run Rgdns::Webhook::App.new
        end

        map "/resque" do
          run Resque::Server.new
        end
      end
    end
  end
end

