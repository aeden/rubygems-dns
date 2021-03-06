#--
# Copyright (c) 2010-2011 Jeremy Hinegardner & Anthony Eden
# All rights reserved.  See LICENSE and/or COPYING for details
#++

module Rgdns 
  #
  # module containing all the version information about rgdns (Rubygems DNS)
  #
  module Version

    # Major version number
    MAJOR   = 0

    # Minor version number
    MINOR   = 1

    # Build number
    PATCH   = 0

    #
    # :call-seq:
    #   Version.to_a -> [ MAJOR, MINOR, PATCH ]
    #
    # Return the version as an array of Integers
    #
    def self.to_a
      [MAJOR, MINOR, PATCH]
    end

    #
    # :call-seq:
    #   Version.to_s -> "MAJOR.MINOR.PATCH"
    #
    # Return the version as a String with dotted notation
    #
    def self.to_s
      to_a.join(".")
    end

    #
    # :call-seq:
    #   Version.to_hash -> { :major => ..., :minor => ..., :patch => ... }
    #
    # Return the version as a Hash
    #
    def self.to_hash
      { :major => MAJOR, :minor => MINOR, :patch => PATCH }
    end

    # The Version in MAJOR.MINOR.PATCH dotted notation
    STRING = Version.to_s
  end

  # The Version in MAJOR.MINOR.PATCH dotted notation
  VERSION = Version.to_s
end

