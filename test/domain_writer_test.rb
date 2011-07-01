require 'test_helper'
require 'rgdns'

class DomainWriterTest < Test::Unit::TestCase
  def test_write_domain
    domain_writer = Rgdns::DomainWriter.new
    records = domain_writer.write(specification)
    records.each { |r| puts r.join("\t") }
  end

  def test_op_transform_version_equal
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version("=", "1.2.3")
    assert_equal res.join("."), "3.2.1"
  end

  def test_op_transform_version_twiddlewakka
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version("~>", "1.2.3")
    assert_equal res.join("."), "2.1"
    res = domain_writer.op_transform_version("~>", "2.3")
    assert_equal res.join("."), "2"
    res = domain_writer.op_transform_version("~>", "1")
    assert_equal res.join("."), ""
  end

  def test_op_transform_version_greater_than
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version(">", "1.2.3")
    assert_equal res.join("."), ""
  end

  def test_op_transform_version_greater_than
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version(">=", "1.2.3")
    assert_equal res.join("."), ""
  end

  def test_op_transform_version_less_than
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version("<", "1.2.3")
    assert_equal res.join("."), "lt.3.2.1"
  end

  def test_op_transform_version_less_than
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version("<=", "1.2.3")
    assert_equal res.join("."), "lte.3.2.1"
  end

  def test_op_transform_version_not_equal
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version("!=", "1.2.3")
    assert_equal res.join("."), "ne.3.2.1"
  end

  private
  def specification
    Gem::Specification.new do |spec|
      spec.name         = 'amalgalite'
      spec.version      = '1.1.2'

      # add dependencies here
      spec.add_dependency("arrayfields", "~> 4.7.4")
      spec.add_dependency("fastercsv", "~> 1.5.4")

      spec.add_development_dependency("rake"         , "~> 0.8.7")
      spec.add_development_dependency("configuration", "~> 1.2.0")
      spec.add_development_dependency("rspec"        , "~> 2.5.1")
      spec.add_development_dependency("rake-compiler", "~> 0.7.6")
      spec.add_development_dependency('zip'          , "~> 2.0.2")
      spec.add_development_dependency('rcov'         , "~> 0.9.9")

    end
  end
end
