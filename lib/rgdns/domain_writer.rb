module Rgdns
  class DomainWriter
    def write(specification)
      fqdn = name_version_to_qname(specification.name, specification.version)
      fqdn_devel = name_version_to_qname(specification.name + "-devel", specification.version)

      specification.runtime_dependencies.each do |dep|
         [fqdn, "PTR", 86400, dependency_to_qname(dep)]
      end
      specification.development_dependencies.each do |dep|
         [fqdn_devel, "PTR", 86400, dependency_to_qname(dep)]
      end
    end

    def dependency_to_qname(dependency)
      op, version = dependency.requirement.requirements.first
      name_op_version_to_qname(dependency.name, op, version)
    end

    def name_version_to_qname(name, version)
      vr = version.to_s.split(".").reverse 
      (vr + [name, "index.rubygems.org"]).join(".")
    end

    def name_op_version_to_qname(name, op, version)
      vr = op_transform_version(op, version)
      (vr + [name, "index.rubygems.org"]).join(".")
    end

    def op_transform_version(op, version)
      vr = version.to_s.split(".").reverse
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
