module Rgdns
  class DomainWriter
    def write(specification)
      build_records(specification)
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

    def build_records(specification)
      records = []

      dn = dn(specification)
      fqdn = fqdn(specification)
      fqdn_latest = fqdn_latest(specification)
      fqdn_devel = fqdn_devel(specification)

      # SOA record
      records << [dn, "SOA", 86400, "ns1.rubygems.org admin@rubygems.org #{Time.now.strftime("%Y%m%d%H%M01")} 86400 7200 604800 300"]

      # NS records
      records << [dn, "NS", 3600, "ns1.rubygems.org"]
      records << [dn, "NS", 3600, "ns2.rubygems.org"]

      # CNAME records
      records << [fqdn_latest, "CNAME", 600, fqdn]
      vr = specification.version.to_s.split(".").reverse
      while vr.shift
        break if vr.empty?
        records << [name_version_to_qname(specification.name, vr), "CNAME", 600, fqdn]
      end

      # PTR record for latest version
      records << [dn, "PTR", 86400, fqdn]

      # PTR records for dependencies
      specification.runtime_dependencies.each do |dep|
         records << [fqdn, "PTR", 86400, dependency_to_qname(dep)]
      end
      specification.development_dependencies.each do |dep|
         records << [fqdn_devel, "PTR", 86400, dependency_to_qname(dep)]
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
  end
end
