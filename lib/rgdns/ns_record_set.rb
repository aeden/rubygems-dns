module Rgdns
  class NsRecordSet
    include Storable 

    attr_reader :domain
    def initialize(domain)
      @domain = domain
    end

    def save(db)
      @db = db
      upsert_ns_records(domain.id, domain.name)
    end

    protected
    def name_servers
      %w(ns1.rubygems.org ns2.rubygems.org)
    end

    def upsert_ns_records(domain_id, dn)
      name_servers.each do |name|
        ns_record = NsRecord.new(domain, dn, name) 
        ns_record.save(db)
      end
    end
  end
end
