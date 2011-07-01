module Rgdns
  class DomainWriter
  
    def write(specification)
      dn = dn(specification)
      
      domain_id = upsert_domain(dn)
      upsert_soa_record(domain_id, dn)
      upsert_ns_records(domain_id, dn)

      build_records(domain_id, specification)
      #records = build_records(specification)
      #records.each do |record|
        #records_table.insert(
          #:domain_id => domain_id,
          #:name => record[0],
          #:type => record[1],
          #:ttl => record[2],
          #:content => record[3],
          #:change_date => Time.now.to_i
        #)
      #end
    end

    # Insert or update the domain record and return the domain id.
    def upsert_domain(dn)
      row = domains_table.filter(:name => dn).first
      unless row && domain_id = row[:id]
        domains_table.insert(:name => dn, :type => 'NATIVE')
        domain_id = domains_table.filter(:name => dn).first[:id]
      end
      domain_id
    end
    protected :upsert_domain

    def upsert_soa_record(domain_id, dn)
      soa_record = records_table.filter(:domain_id => domain_id, :name => dn, :type => "SOA").first 
      insert_record(domain_id, dn, "SOA", 86400, soa_content) unless soa_record
    end
    protected :upsert_soa_record

    def soa_content
      "ns1.rubygems.org admin@rubygems.org #{Time.now.strftime("%Y%m%d%H%M01")} 86400 7200 604800 300"
    end
    private :soa_content

    def upsert_ns_records(domain_id, dn)
      %w(ns1.rubygems.org ns2.rubygems.org).each do |name|
        ns_record = records_table.filter(:domain_id => domain_id, :name => dn, :type => "NS", :content => name).first
        insert_record(domain_id, dn, "NS", 3600, name) unless ns_record
      end
    end
    protected :upsert_ns_records

    def upsert_latest_ptr(domain_id, fqdn_latest, fqdn)
      latest_ptr_record = records_table.filter(:domain_id => domain_id, :name => fqdn_latest, :type => "CNAME").first
      if latest_ptr_record
        records_table.filter(:id => latest_ptr_record[:id]).update(:content => fqdn)
      else
        insert_record(domain_id, fqdn_latest, "CNAME", 600, fqdn) 
      end
    end
    protected :upsert_latest_ptr

    def upsert_partial_versions(domain_id, specification)
      fqdn = fqdn(specification)
      vr = specification.version.to_s.split(".").reverse
      while vr.shift
        break if vr.empty?
        name = name_version_to_qname(specification.name, vr)
        record = records_table.filter(:domain_id => domain_id, :name => name).first
        if record
          records_table.filter(:id => record[:id]).update(:content => fqdn, :change_date => Time.now.to_i)
        else
          insert_record(domain_id, name, "CNAME", 600, fqdn)
        end
      end
    end

    def insert_record(domain_id, name, type, ttl, content)
      records_table.insert(
        :domain_id => domain_id,
        :name => name,
        :type => type, 
        :ttl => ttl, 
        :content => content,
        :change_date => Time.now.to_i
      )
    end
    private :insert_record

    def insert_record_if_new(domain_id, name, type, ttl, content)
      record = records_table.filter(:domain_id => domain_id, :name => name, :type => type, :content => content).first
      insert_record(domain_id, name, type, ttl, content) unless record
    end
    private :insert_record_if_new

    def build_records(domain_id, specification)
      records = []

      dn = dn(specification)
      fqdn = fqdn(specification)
      fqdn_latest = fqdn_latest(specification)
      fqdn_devel = fqdn_devel(specification)

      # CNAME records
      upsert_latest_ptr(domain_id, fqdn_latest, fqdn)
      upsert_partial_versions(domain_id, specification)

      # PTR record for latest version
      insert_record_if_new(domain_id, dn, "PTR", 86400, fqdn)

      # PTR records for dependencies
      specification.runtime_dependencies.each do |dep|
        insert_record_if_new(domain_id, fqdn, "PTR", 86400, dependency_to_qname(dep))
      end
      specification.development_dependencies.each do |dep|
        insert_record_if_new(domain_id, fqdn_devel, "PTR", 86400, dependency_to_qname(dep))
      end

      records
    end

    def dependency_to_qname(dependency)
      op, version = dependency.requirement.requirements.first
      name_op_version_to_qname(dependency.name, op, version)
    end
    
    def name_to_domain(name)
      [name, base_name].join(".")
    end

    def name_version_to_qname(name, version)
      (version_as_reverse_array(version) + [name, base_name]).join(".")
    end

    def name_op_version_to_qname(name, op, version)
      vr = op_transform_version(op, version)
      (vr + [name, base_name]).join(".")
    end

    def version_as_reverse_array(version)
      case version
      when Array then version
      when Gem::Version then version_as_reverse_array(version.to_s)
      when String then version.split(".").reverse
      else
        raise "Can't handle versin #{version}"
      end
    end

    def base_name
      "index.rubygems.org"
    end

    def op_transform_version(op, version)
      vr = version_as_reverse_array(version)
      case op
      when '=' then vr
      when '~>' then vr.shift
      when '>=' then vr.clear
      when '>' then vr.clear
      when '<' then vr.unshift('lt')
      when '<=' then vr.unshift('lte')
      when '!=' then vr.unshift('ne')
      end
      vr
    end

    private

    def db_url
      db_url = ENV['DB_URL'] || 'mysql://root@localhost/powerdns'
    end
    def db 
      @db ||= Sequel.connect(db_url)
    end

    def domains_table
      @domains_table ||= db[:domains]
    end

    def records_table
      @records_table ||= db[:records]
    end

    def fqdn(specification)
      @fqdn ||= name_version_to_qname(specification.name, specification.version)
    end

    def fqdn_devel(specification)
      @fqdn_devel ||= name_version_to_qname(specification.name + "-devel", specification.version)
    end

    def dn(specification)
      @dn ||= name_to_domain(specification.name)
    end

    def fqdn_latest(specification)
      @fqdn_latest ||= ["latest", fqdn(specification)].join(".")
    end

  end
end
