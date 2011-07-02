module Rgdns
  class Record
    include Storable

    attr_reader :domain
    attr_reader :name
    attr_reader :type

    attr_accessor :ttl
    attr_accessor :content

    def initialize(domain, name)
      @domain = domain
      @name = name
    end

    def ttl
      @ttl ||= 3600
    end

    def save(db)
      @db = db
      save_record
    end

    protected
    # Set the record type
    def type=(type)
      @type = type
    end

    def save_record
      raise NotImplementedError, "Subclass must implement save_record"
    end

    # Insert the given record
    def insert_record(name, type, ttl, content)
      records_table.insert(
        :domain_id => domain.id,
        :name => name,
        :type => type, 
        :ttl => ttl, 
        :content => content,
        :change_date => Time.now.to_i
      )
    end

    # Only insert the given record if the record does not yet exist
    def insert_record_if_new(name, type, ttl, content)
      record = records_table.filter(:domain_id => domain.id, :name => name, :type => type, :content => content).first
      insert_record(name, type, ttl, content) unless record
    end
  end
end
