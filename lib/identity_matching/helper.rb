# helper.rb
# define globally available helper functions
require "uri"
require "json"
require "erb"
require_relative "match_request"
require 'active_support/core_ext/string'

module IdentityMatching
  module Helper

    def load_resource( filename )
      filepath = File.join( __dir__, '..', '..', 'resources', filename )
      File.read(filepath)
    end
  end
end

