require 'rgdns/webhook/logger'

module Rgdns::Webhook
  # A sinatra app for accepting webhook posts from rubygems.org and 
  #
  # == Options
  class App < ::Sinatra::Base

    include Rgdns::Loggable

    def initialize( app = nil, options = {} )
      @app = app
      super( @app )
      if options[:redis] then
        Resque.redis = options[:redis]
      end
      @redis = Resque.redis
    end

    get '/accept' do
      error(405, "I think you want a POST request")
    end

    post '/accept' do
      begin
        submit_job( request.body.read )
        halt 202
      rescue => e
        logger.error e.message
        e.backtrace.each do |b|
          logger.debug b
        end
        error(500, e.message)
      end
    end

    def submit_job( json )
      data = JSON.parse( json )
      gemfile = File.basename( URI.parse( data['gem_uri'] ).path )
      logger.info "Submitting #{gemfile}"
      Resque.enqueue( Rgdns::ResqueJobs::FetchStore,  gemfile )
    end
  end
end

