require 'inferno/dsl/oauth_credentials'
require_relative 'identity_matching/technical'
require_relative 'identity_matching/capability_statement'
require_relative 'identity_matching/match_operation'
require_relative 'identity_matching/digital_identity'
require_relative 'identity_matching/identity_assurance'
require_relative 'identity_matching/patient_matching'
require_relative 'identity_matching/match_request'
require_relative 'identity_matching/fhir_artifacts'
require_relative 'identity_matching/helper'

module IdentityMatching
  class Suite < Inferno::TestSuite
    include IdentityMatching::Helper

    id :identity_matching
    title 'Identity Matching'
    description 'Test Suite for Digital Identity & Patient Matching FHIR Implementation Guide'

    # This input will be available to all tests in this suite
    input :url,
        title: 'FHIR endpoint',
        description: 'URL of FHIR endpoint',
        default: 'http://host.docker.internal:3000/baseR4/'

    input :access_token,
        title: 'Bearer Token',
        default: 'Y3YWq2l08kvFqy50fQJY',
        optional: true

    input :strict,
      title: 'Strict testing (include SHOULD and MAY cases)',
      type: 'radio',
      default: 'false',
      options: {
        list_options: [
          { label: 'True', value: true },
          { label: 'False', value: false }
        ]
      }

    # All FHIR requests in this suite will use this FHIR client
    fhir_client do
      url :url
    end

    # Now load actual test groups
    group from: :technical
    group from: :capability_statement

    #group from: :im_patient_match_operation

    group from: :identity_assurance
    group from: :patient_matching
    group from: :digital_identity
    # group from: :fhir_artifacts (redundant - weight tests are in section 4)

  end

end
