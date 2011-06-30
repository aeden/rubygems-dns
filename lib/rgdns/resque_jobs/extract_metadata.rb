module Rgdns 
  module ResqueJobs
    class ExtractMetadata < ResqueJob
      attr_accessor :gemfile
      attr_accessor :contents

      @queue = :extract_metadata

      def self.perform( gemfile, contents )
        job = ExtractMetadata.new( gemfile, contents )
        job.run
      end

      def initialize( gemfile, contents )
        @gemfile = gemfile
        @contents = Base64.decode64(contents) 
      end

      def run
        begin
          logger.info "Starting extraction of metadata from #{@gemfile}"
          metadata = Rgdns::GemVersionData.new( contents )
         
          logger.info "Writing to DNS database"
          domain_writer = Rgdns::DomainWriter.new
          domain_writer.write(metadata.specification)

        rescue Gem::Package::FormatError => e
          logger.warn "<#{e.class} #{e.message}> means #{@gemfile} cannot opened by Ruby #{RUBY_VERSION} with Rubygems #{Gem::VERSION}"
        rescue ArgumentError => e
          # unfortunately, this is the only way to skip this error
          if e.backtrace[0] =~ /normalize_yaml_input/ then
          #if e.message == "invalid byte sequence in UTF-8" then
            logger.warn "<#{e.class} #{e.message}> means #{@gemfile} cannot opened by Ruby #{RUBY_VERSION} with Rubygems #{Gem::VERSION}"
          else
            log_and_reraise( e )
          end
        rescue => e
          log_and_reraise( e )
        ensure
          logger.info "Finished extraction of metadata from #{@gemfile}"
        end
      end
    end
  end
end

