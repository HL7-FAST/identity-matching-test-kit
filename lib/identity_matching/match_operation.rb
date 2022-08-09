require "uri"
require "json"
require "net/http"
require 'webmock/rspec'
require 'logger'
require_relative 'match_request'

module IdentityMatching
 
  class PatientMatching < Inferno::TestGroup
    #include MatchRequest

    title 'Match Operation Tests'
    description 'Verify support for the $match operation required by the Patient Matching profile.'
    id :im_patient_match_operation

=begin
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
=end
    test do
      id :patient_match_base
      title 'Patient match is valid'
      description %(
        Verify that the Patient  $match resource returned from the server is a valid FHIR resource.
      )
=begin
      input :search_json,
        title: 'Patient resource',
        description: 'Patient resource used to find matches'
=end
      input :profile_level,
        title: "Profile (Base | L0 | L1)",
        optional: false,
        default: 'L0'

      input :certain_matches_only,
        title: "Return only certain matches (yes | no)",
        default: 'no'

      input :given_name,
        title: 'First Name',
        optional: true
      input :middle_name,
        title: 'Middle Name',
        optional: true
      input :last_name,
        title: 'Last Name',
        optional: true
      input :date_of_birth,
        title: 'Date of Birth',
        optional: true,
        default: ''
      input :sex,
        title: 'Sex (assigned at birth) (F | M)',
        optional: true

      input :phone_number,
        title: 'Phone Number',
        optional: true

      input :email,
        title: 'Email Address',
        optional: true

      input :street_address,
        title: 'Address - Street',
        optional: true
      input :city,
        title: 'Address - City',
        optional: true
      input :state,
        title: 'Address - State',
        optional: true
      input :postal_code,
        title: 'Address - Postal Code',
        optional: true

      input :passport_number,
        title: 'Passport Number',
        optional: true

      input :state_id,
        title: 'State ID',
        optional: true

      input :drivers_license_number,
        title: "Driver's License Number",
        optional: true
      
      input :insurance_number,
        title: 'Insurance Subscriber Identifier',
        optional: true

      input :medical_record_number,
        title: 'Medical Record Number',
        optional: true

      input :master_patient_index,
        title: 'Master Patient Index',
        optional: true

      output :response_json
      # Named requests can be used by other tests
      makes_request :match_operation
      
      
       # create a "default" client for a group
       
      logger= Logger.new(STDOUT)
      # create a named client for a group

      run do
         #fhir_operation ("Patient/$match", body: body, client: :default, name: match_operation, headers: { 'Content-Type': 'application/fhir+json' })
          @match_request = MatchRequest.new( last_name, given_name, middle_name, date_of_birth, sex, phone_number, email, street_address, city, state, postal_code, 
            passport_number, drivers_license_number, state_id, master_patient_index, medical_record_number, insurance_number, profile_level, certain_matches_only)
          puts "Driver's License: #{@match_request.drivers_license_number}"
          puts "Identifiers: #{@match_request.identifiers}"
          puts "Profile: #{@match_request.profile}"
          puts "Certain Matches Only: #{@match_request.certain_matches_only}"
=begin
          MATCH_PARAMETER = ERB.new(File.read("resources/search_parameter.json.erb"))
          @json_request = MATCH_PARAMETER.result_with_hash({model: @match_request})
=end
          
          file  = File.read("resources/test_search_parameter.json.erb")
          @json_request = JSON.parse(file)

          #body = @match_request.build_request_fhir
          #puts "JSON Request #{body}"

          #response_json=response[:body]
          #output response_json: response[:body]
          #assert_response_status(200)
          #assert_valid_bundle_entries(resource_types: 'Patient')
             
      end
    end
=begin
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
      uses_request :match_operation

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
=end
  end
end