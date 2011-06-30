require 'sequel'
require 'rubygems/specification'
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
        specs << eval( r )
      end
      return specs
    end
  end
end
