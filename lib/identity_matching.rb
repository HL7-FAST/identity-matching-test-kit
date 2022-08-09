require 'inferno/dsl/oauth_credentials'
require_relative 'identity_matching/match_operation'
#require_relative 'identity_matching/digital_identity'
#require_relative 'identity_matching/identity_assurance'
#require_relative 'identity_matching/patient_matching'

module IdentityMatching
  class Suite < Inferno::TestSuite
    id :im
    title 'Identity Matching'
    description 'Test suite for Identity Matching'

    # This input will be available to all tests in this suite
    input :url,
        title: 'FHIR endpoint',
        description: 'URL of FHIR endpoint'

    
    input :access_token
    
    # All FHIR requests in this suite will use this FHIR client
    fhir_client do
      url :url
    end

=begin
    fhir_client :with_custom_headers do
      url :url
      bearer_token :access_token
    end
=end
    # Tests

    group do
      id :capability_statement
      title 'Capability Statement'
      description 'Verify that the server has a CapabilityStatement'

      test do
        id :capability_statement_read
        title 'Read CapabilityStatement'
        description 'Read CapabilityStatement from /metadata endpoint'

        run do
          fhir_get_capability_statement

          assert_response_status(200)
          assert_resource_type(:capability_statement)

        end
      end
  
    end    
    #group from: :im_patient_match_operation

    # Specify identity match test groups
    #group from: :digital_identity
    #group from: :identity_assurance
    #group from: :patient_matching
  end
end
