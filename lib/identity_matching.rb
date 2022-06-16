require 'inferno/dsl/oauth_credentials'
require_relative 'identity_matching/match_operation'
#require_relative 'identity_matching/digital_identity'
#require_relative 'identity_matching/identity_assurance'
#require_relative 'identity_matching/patient_matching'

require_relative 'identity_matching/match_operation'

module IdentityMatching
  class Suite < Inferno::TestSuite
    id :identity_matching
    title 'Identity Matching'
    description 'Test suite for Identity Matching'

    # This input will be available to all tests in this suite
    input :url,
        title: 'FHIR endpoint',
        description: 'URL of FHIR endpoint'
    #begin
    input :smart_credentials,
        title: 'OAuth credentials',
        type: :oauth_credentials,
        optional: true
    #end

    # All FHIR requests in this suite will use this FHIR client
    fhir_client do
      url :url
      #, oauth_credentials :smart_credentials ***ENABLE WHEN SERVER READY ****
    end

    group do
      id :capability_statement
      title 'Capability Statement'
      description 'Verify that the server has a CapabilityStatement'

      test do
        id :capability_statement_read
        title 'Read CapabilityStatement'
        description 'Read CapabilityStatement from /metadata endpoint'

        run do
          fhir_client.set_no_auth
          fhir_get_capability_statement

          assert_response_status(200)
          assert_resource_type(:capability_statement)
          assert_valid_resource

        end
      end
    end    

    # Specify identity match test groups
    
    group from: :match_operation
    #group from: :digital_identity
    #group from: :identity_assurance
    #group from: :patient_matching
  end
end
