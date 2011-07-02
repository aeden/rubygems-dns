require 'test_helper'
require 'rgdns'

class DomainWriterTest < Test::Unit::TestCase
  def with_clean_db
    db_url = "mysql://root@localhost/powerdns"
    db = Sequel.connect(db_url)
    db[:domains].delete
    db[:records].delete
    yield db
  end

  def test_write_domain
    with_clean_db do |db|
      domain_writer = Rgdns::DomainWriter.new
      domain_writer.write(specification)

      assert_equal 1, db[:domains].filter(:name => "amalgalite.index.rubygems.org").count
      assert_equal 1, db[:records].filter(:name => "amalgalite.index.rubygems.org", :type => "SOA").count
      assert_equal 2, db[:records].filter(:name => "amalgalite.index.rubygems.org", :type => "NS").count
      assert_equal 1, db[:records].filter(:name => "amalgalite.index.rubygems.org", :type => "PTR").count
      
    end
  end

  def test_op_transform_version_equal
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version("=", "1.2.3")
    assert_equal res.join("."), "3.2.1"
  end

  def test_op_transform_version_twiddlewakka
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version("~>", "1.2.3")
    assert_equal "2.1", res.join(".")
    
    res = domain_writer.op_transform_version("~>", "2.3")
    assert_equal "2", res.join(".")
    
    res = domain_writer.op_transform_version("~>", "1")
    assert_equal "", res.join(".")
  end

  def test_op_transform_version_greater_than
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version(">", "1.2.3")
    assert_equal "", res.join(".")
  end

  def test_op_transform_version_greater_than
    domain_writer = Rgdns::DomainWriter.new
    res = domain_writer.op_transform_version(">=", "1.2.3")
    assert_equal "", res.join(".")
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
