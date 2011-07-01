require 'sequel';
module Rgdns
  class Gemology
    def initialize( sequel_options )
      @db = Sequel.connect( *sequel_options )
    end

    def specifications
      @specifications ||= fetch_specifications
    end

    def fetch_specifications
      sql = "SELECT specification FROM gem_version_raw_specifications"
      specs = []
      @db.fetch( sql ) do |r|
        specs << r[:specification]
      end
      return specs
    end
  end
end

if $0 == __FILE__ then
  uuid = [ `uuidgen -r`.strip, `uuidgen -r`.strip ]
  delimiter = uuid.join(':')
  g = Rgdns::Gemology.new( ARGV.shift )
  $stdout.puts delimiter
  count = 0
  g.specifications.each do |spec_text|
    $stdout.puts spec_text
    $stdout.puts delimiter
    count += 1
    $stderr.puts count if count % 10000 == 0
  end
end

