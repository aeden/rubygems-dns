module Rgdns
  # Mix this module in to get table accessors
  module Storable
    protected
    def db
      @db
    end
    def domains_table
      db[:domains]
    end
    def records_table
      db[:records]
    end
  end
end
