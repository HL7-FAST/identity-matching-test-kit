

require_relative 'inferno_template/patient_group'

module InfernoTemplate
  class Suite < Inferno::TestSuite
    id :test_suite_template
    title 'Identity Matching Test Kit'
    description 'A basic test suite template for Inferno'

    # This input will be available to all tests in this suite
    input :url
    input :access_token

    # All FHIR requests in this suite will use this FHIR client
    #fhir_client do
    #  url :url
    #end
    fhir_client  do
      url :url
    end

    fhir_client :with_custom_headers do
      url :url
      bearer_token :access_token
    end
    # Tests and TestGroups can be defined inline
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

    # Tests and TestGroups can be written in separate files and then included
    # using their id
    group from: :patient_group
  end
end