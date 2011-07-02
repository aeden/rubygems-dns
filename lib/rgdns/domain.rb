module Rgdns
  class Domain
    include Storable

    attr_reader :id
    attr_reader :name

    def initialize(name)
      @name = name
    end

    # Save to the specified database.
    def save(db)
      @db = db
      save_domain
    end

    protected
    def save_domain
      upsert_domain(name)

      soa_record = SoaRecord.new(self)
      soa_record.save(db)

      ns_record_set = NsRecordSet.new(self)
      ns_record_set.save(db)
    end

    def upsert_domain(dn)
      row = domains_table.filter(:name => dn).first
      unless row && domain_id = row[:id]
        domains_table.insert(:name => dn, :type => 'NATIVE')
        @id = domains_table.filter(:name => dn).first[:id]
      end
      @id 
    end
  end
end
