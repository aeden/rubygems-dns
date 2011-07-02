module Rgdns
  class NsRecord < Record
    def initialize(domain, name, ns_name)
      super(domain, name)
      self.type = "NS"
      self.content = ns_name
    end

    protected
    def save_record
      ns_record = records_table.filter(:domain_id => domain.id, :name => name, :type => type, :content => content).first
      insert_record(name, type, ttl, name) unless ns_record
    end
  end
end
