require 'test_helper'
require 'resolv/naptr'

class NaptrTest < Test::Unit::TestCase
  def test_naptr_resolution
    results = []
    resolver = Resolv::DNS.new
    resolver.each_resource('0.0.1.example.index.dnsimple.org', Resolv::DNS::Resource::IN::NAPTR) do |res|
      results << res 
    end
    #assert !results.empty?
  end
end
