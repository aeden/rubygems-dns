$:.unshift('lib')
require 'rgdns'

app = Rgdns::Web.new.app
run app

