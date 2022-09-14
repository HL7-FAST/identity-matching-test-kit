require "uri"
require "json"
require "erb"
require "net/http"
require "webmock/rspec"
require "logger"
require_relative "match_request"

module IdentityMatching
  class CapabilityStatement < Inferno::TestGroup

    title 'Capability Statement Tests'
    description 'Verify conformant FHIR CapabilityStatement'
    id :capability_statement

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

    test do
      id = 'capability_statement_for_match'
      title 'Identity Matching Server declares support for $match operation in Capability Statement'
      description %(
        The Identity Matching Server SHALL declare support for Patient/$match operation in its server CapabilityStatement
      )

      run do
        fhir_get_capability_statement
        assert_response_status(200)
        assert_resource_type(:capability_statement)

        operations = resource.rest&.flat_map do |rest|
          rest.resource
            &.select { |r| r.type == 'Patient' && r.respond_to?(:operation) }
            &.flat_map(&:operation)
        end&.compact

        operation_defined = operations.any? do |operation|
          operation.definition == 'http://hl7.org/fhir/OperationDefinition/Patient-match' ||
            ['patient', 'patient-match'].include?(operation.name.downcase)
        end

        assert operation_defined, 'Server CapabilityStatement did not declare support for $match operation in Patient resource.'
      end
    end

  end
end
