require 'test_helper'
require 'rgdns'

class LoggableTest < Test::Unit::TestCase
  include Rgdns::Loggable
  def test_loggable
    assert_not_nil logger 
    logger.debug 'foo'
  end
end
