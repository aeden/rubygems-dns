module Rgdns 
  module ResqueJobs
    class FetchStore < ResqueJob
      attr_accessor :client
      attr_accessor :gemfile

      include Rgdns::Loggable

      @queue = :fetch_store

      def self.perform( gemfile )
        job = FetchStore.new( gemfile )
        job.run
      end

      def initialize( gemfile )
        @client = RubygemsClient.new
        @gemfile = gemfile
        logger.info "Starting fetch and store of #{@gemfile}"
      end

      def run
        fname = File.basename(gemfile)

        logger.info "Fetching #{gemfile}"
        contents = client.gemfile(gemfile) 

        logger.info "Finished fetch of #{gemfile}"
        Resque.enqueue(Rgdns::ResqueJobs::ExtractMetadata, gemfile, Base64.encode64(contents))
      rescue => e
        log_and_reraise(e)
      end
    end
  end
end

