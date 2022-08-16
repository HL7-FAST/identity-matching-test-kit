# helper.rb
# define globally available helper functions


module IdentityMatching
  module Helper

    def load_resource( filename )
      filepath = File.join( __dir__, '..', '..', 'resources', filename )
      File.read(filepath)
    end

  end
end

