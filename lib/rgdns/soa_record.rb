module Rgdns
  class SoaRecord < Record
    attr_reader :domain

    def initialize(domain)
      @domain = domain
    end

    protected
    def save_record
      upsert_soa_record(domain.id, domain.name)
    end

    def upsert_soa_record(domain_id, dn)
      soa_record = records_table.filter(:domain_id => domain_id, :name => dn, :type => "SOA").first 
      insert_record(dn, "SOA", 86400, soa_content) unless soa_record
    end

    private
    def soa_content
      "ns1.rubygems.org admin@rubygems.org #{Time.now.strftime("%Y%m%d%H%M01")} 86400 7200 604800 300"
    end
  end
end
