require "uri"
require "json"
require "net/http"
require 'webmock/rspec'
require 'logger'

module IdentityMatching
 
  class MatchOperation < Inferno::TestGroup
    title 'Match Operation Tests'
    description 'Verify support for the $match operation required by the Patient Matching profile.'
    id :im_patient_match_operation

    test do
      title 'Identity Matching Server declares support for $match operation in CapabilityStatement'
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

    
    test do
      title 'Patient match is valid'
      description %(
        Verify that the Patient  $match resource returned from the server is a valid FHIR resource.
      )
      input :search_json,
      title: 'Patient',
      description: 'Patient resource used to find matches'
      output :response_json
      # Named requests can be used by other tests
      makes_request :match
      
      
       # create a "default" client for a group
      # fhir_client do
       #  url :url
      #end
      logger= Logger.new(STDOUT)
      # create a named client for a group
      fhir_client  do
        url :url
      end
      #fhir_client :with_custom_header do
      #  url :url
      #  headers { 'Content-Type': 'application/fhir+json' }
     #end
      run do
        body = JSON.dump(search_json)
         
          response=JSON.parse(body)
          puts("patientName" +   response[:total])
         fhir_operation ("Patient/$match", body: body, client: :default, name: nil, headers: { 'Content-Type': 'application/fhir+json' })

          
          #response_json=response[:body]
          output response_json: response[:body]
          assert_response_status(200)
          assert_resource_type(:bundle)
             
      end
    end
    test do
      input :response_json
      title 'Patient match - determines whether or not the $match function returns every valid record'
      description %(Match output SHOULD contain every record of every candidate identity, subject to volume limits
      )
      run do
        puts response_json
        response=JSON.parse(response_json)
        puts("Entry Count=" +   response[:total])
      end
    end

    test do
      title 'Server returns a fully bundled patient records from a Patient resource'
      description %(
        This test will perform the $match operation on the chosen patient resource with the persist option on.
        It will verify that all matched patients are in the patient bundle and that we are able to retrieve the bundle after it's generated.
      )
      # link 'https://www.hl7.org/fhir/patient-operation-match.html'

      input :patient_resource
      makes_request :match_operation

    run do
      fhir_read(:patient, patient_id)

      assert_response_status(200)
      assert_resource_type(:patient)
      assert resource.id == patient.id,
              "Requested resource with id #{patient.id}, received resource with id #{resource.id}"

      assert_valid_resource(profile_url: 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient')

      patient_out = resource
      matched_patients = []
      patient_out.each_element do |value, meta, _path|
        next if meta['type'] != 'searchset'
        next if value.reference.blank?

        matched_patients << value
      end

      fhir_operation("Patient/#{patient_out.id}/$match?persist=true", name: :match_operation)
      assert_response_status(200)
      assert_resource_type(:bundle)
    end

    test do
      title 'Server returns Bundle resource for Patient/$match operation'
      description %(
        Server return valid Bundle resource as successful result of $match operation
        POST [base]/Patient/$match
      )
      # link 'https://www.hl7.org/fhir/patient-operation-match.html'
      uses_request :match_operation

      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

        assert_valid_resource(profile_url: 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient')
      end
    end

    test do
      title 'Server returns Bundle resource containing valid Patient entry'
      description %(
        Server return valid Patient resource in the Bundle as first entry
      )
      # link 'https://www.hl7.org/fhir/patient-operation-match.html'
      uses_request :match_operation

      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

        assert resource.entry.length.positive?, 'Bundle has no entries'

        entry = resource.entry.first

        assert entry.resource.is_a?(FHIR::Patient), 'The first entry in the Bundle is not a Patient'
        assert_valid_resource(resource: entry, profile_url: 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient')
      end
    end
  end
end