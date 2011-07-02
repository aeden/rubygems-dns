require 'sequel'

require 'rgdns/storable'
require 'rgdns/domain'
require 'rgdns/record'
require 'rgdns/soa_record'
require 'rgdns/ns_record'
require 'rgdns/ns_record_set'

module Rgdns
  class DomainWriter
  
    def write(specification)
      dn = dn(specification)

      domain = Rgdns::Domain.new(dn)
      domain.save(db)
      
      insert_records(domain.id, specification)
    end

    def upsert_latest_cname(domain_id, fqdn_latest, fqdn)
      latest_cname_record = records_table.filter(:domain_id => domain_id, :name => fqdn_latest, :type => "CNAME").first
      if latest_cname_record
        records_table.filter(:id => latest_cname_record[:id]).update(:content => fqdn)
      else
        insert_record(domain_id, fqdn_latest, "CNAME", 600, fqdn) 
      end
    end
    protected :upsert_latest_cname

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
    protected :upsert_partial_versions

    def insert_partial_versions(domain_id, specification)
      fqdn = fqdn(specification)
      vr = specification.version.to_s.split(".").reverse
      while vr.shift
        break if vr.empty?
        name = name_version_to_qname(specification.name, vr)
        record = records_table.filter(:domain_id => domain_id, :name => name).first
        insert_record(domain_id, name, "CNAME", 600, fqdn) unless record
      end
    end
    protected :insert_partial_versions

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

    def insert_records(domain_id, specification)
      dn = dn(specification)
      fqdn = fqdn(specification)
      fqdn_latest = fqdn_latest(specification)
      fqdn_devel = fqdn_devel(specification)

      # CNAME records
      if latest?(specification)
        upsert_latest_cname(domain_id, dn_latest(specification), fqdn) 
        upsert_partial_versions(domain_id, specification)
      else
        insert_partial_versions(domain_id, specification)
      end

      # PTR record for latest version
      insert_record_if_new(domain_id, dn, "PTR", 86400, fqdn)

      # PTR records for dependencies
      specification.runtime_dependencies.each do |dep|
        insert_record_if_new(domain_id, fqdn, "PTR", 86400, dependency_to_qname(dep))
      end
      specification.development_dependencies.each do |dep|
        insert_record_if_new(domain_id, fqdn_devel, "PTR", 86400, dependency_to_qname(dep))
      end
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
      vr = ['latest'] if vr.empty?
      (vr + [name, base_name]).join(".")
    end

    def version_as_reverse_array(version)
      case version
      when Array then version
      when Gem::Version then version_as_reverse_array(version.to_s)
      when String then version.split(".").reverse
      else
        raise "Can't handle version #{version}"
      end
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

    def latest
      @latest ||= {}
    end

    def latest?(specification)
      current_latest = latest[specification.name]
      if current_latest.nil? || specification.version > current_latest
        latest[specification.name] = specification.version
        true
      else
        false
      end
    end

    def base_name
      "index.rubygems.org"
    end

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
      name_version_to_qname(specification.name, specification.version)
    end

    def fqdn_devel(specification)
      name_version_to_qname(specification.name + "-devel", specification.version)
    end

    def dn(specification)
      name_to_domain(specification.name)
    end

    def dn_latest(specification)
      ["latest", dn(specification)].join(".")
    end

    def fqdn_latest(specification)
      ["latest", fqdn(specification)].join(".")
    end

  end
end
