require "uri"
require "json"
require "erb"
require "net/http"
require "webmock/rspec"
require "logger"
require_relative "match_request"
require_relative "helper"

module IdentityMatching
  class PatientMatching < Inferno::TestGroup

    # import all functions defined in module Helper
    include IdentityMatching::Helper

    # test group metadata
    title 'Patient Matching Tests'
    description 'Execute a $match operation at /Patient/$match endpoint on a Master Patient Index (MPI). '
    id :patient_matching

    # filler functions to replace input (for now)
    def expectedResultCnt
      1
    end

    def search_json
      load_resource('test_queries/parameters1.json')
    end

    def patient_id
      2
    end

    # test cases
    test do
      id :end_user_authorization
      title 'Patient-initiated workflows SHALL require end-user authorization'
      description <<~DESC
        If a client or fullstack application allows any patient to make $match queries for themselves, then
        they must have explicit authorization by the subject patient for that information (i.e: OAuth2).
      DESC

      run do
          info "This test is an automatic pass, please see ABOUT."
          pass
      end
    end

    test do
      id :transmitting_identity
      title 'The transmitter of identity attributes with an asserted assurance level SHALL verify the attributes at that assurance level or be consistent with other evidence'
      # TODO desc

      run do
        info "This test is an automatic pass, please see ABOUT."
        pass
      end
    end

    test do
      id :patient_match_base
      title 'Patient match is valid'
      description "Verify that the Patient $match resource returned from the server is a valid FHIR resource."

      makes_request :match_operation

      run do

          json_request = load_resource('test_queries/parameters1.json')
          #puts "======================="
          #puts "DEBUG: #{json_request}"
          #puts "======================="
          fhir_body = FHIR.from_contents(json_request) # needs to be FHIR::Parameters object

          fhir_operation('Patient/$match', body: fhir_body, name: :match_operation);

          assert_response_status(200)
          assert_valid_resource
      end
    end

    test do
      id :every_valid_record
      title 'Patient match - determines whether or not the $match function returns every valid record'
      description %Q(
        Match output SHOULD contain every record of every candidate identity, subject to volume limits
      )

      # Use saved request/response from fhir_operation call in previous test
      uses_request :match_operation

      run do
        response_json = resource.to_json # resource is body from response as FHIR::Model

        puts response_json
        response = JSON.parse(response_json)
        puts("Entry Count = ", response[:total])

        skip "TODO: decide are we returning all records or certain matches?"
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
        assert resource.id == patient_id, "Requested resource with id #{patient_id}, received resource with id #{resource.id}"

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
    end

    test do
      title 'Server returns Bundle resource for Patient/$match operation'
      description <<~DESC
        Server return valid Bundle resource as successful result of $match operation
        POST [base]/Patient/$match
      DESC

      # link 'https://www.hl7.org/fhir/patient-operation-match.html'
      uses_request :match_operation

      run do
        skip_if( !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation' )

        assert_valid_resource({ :profile_url => 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient' })
        # use bundle profile instead?
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

    test do
      title 'Test whether it is possible to gain access to patient data without authenticating'
      description %(Test whether it is possible to gain access to patient data without authenticating -
      This Test attempts to make a $match api call  without providing the authentication credentials)
      #input :access_token;
      #input :search_json ,
      #  type: 'textarea'

      run do
        body = JSON[search_json]
        fhir_operation("Patient/$match", body: body, client: :default, name: :match, headers: { 'Content-Type'=>'application/fhir+json' })
        assert_response_status(401)

      end
    end

    test do
      #input :expectedResultCnt
      #input :response_json
      #output :numberOfRecordsReturned
      title 'Patient match - determines whether or not the $match function returns every valid record'
      description %(Match output SHOULD contain every record of every candidate identity, subject to volume limits)

      uses_request :match_operation

      run do
        response_json = resource.to_json # resource is body from response as FHIR::Model

        #puts response_json
        response = JSON[response_json]
        numberOfRecordsReturned = response['total']
        assert_valid_json(response_json, message = "Invalid JSON response received - expected: #{expectedResultCnt} - received: #{numberOfRecordsReturned}")
        puts "number of records returned in bundle ---- #{numberOfRecordsReturned} "
        puts "number of records expected in bundle ---- #{expectedResultCnt} "
        assert numberOfRecordsReturned.to_i() == expectedResultCnt.to_i(), "Incorrect Number of Records returned"
        #output numberOfRecordsReturned: numberOfRecordsReturned

      end

    end

    test do
      #input :expectedResultCnt
      #input :response_json
      title 'Determine whether or not the records are sorted by ID and Score'
      description %(Match output SHOULD return records sorted by score)

      uses_request :match_operation

      run do

        i =0
        curr_id=0
        prev_id=0
        curr_score=0
        prev_score=0
        is_sorted=true

        response_json = resource.to_json # resource is body from response as FHIR::Model
        responseJSON = JSON.parse(response_json)


        responseJSON["entry"].each do |item|
          curr_score=item.dig("resource","score")
          curr_id=item.dig("resource","id")
          if i  > 0
            if prev_id.to_s >= curr_id.to_s && prev_score.to_s <= curr_score_to_s
            	is_sorted=false
            end
            prev_score=curr_score
            prev_id=curr_id
            i= i + 1
          end
        end
        puts "@@@@@@@@@@@@@   Is Sorted=#{is_sorted}  @@@@@@@@@@"
        assert is_sorted == true, "Returned records are not sorted by patient id ( asc ) and score ( desc) "
      end
    end

    test do
      #input :response_json
      title 'Determine whether or not  the patient.link field references an underlying patient'
      description %(Determine whether or not the patient.link field references an underlying patient)

      uses_request :match_operation

      run do

        response_json = resource.to_json # resource is body from response as FHIR::Model

        responseJSON = JSON.parse(response_json)
        responseJSON["entry"].each do |item|
          puts "got here"
          patientLinkList= item.dig("resource","link")
          puts "****patient Link List=#{patientLinkList}"
          if !patientLinkList.nil?
            patientLinkList.each do |patient_link|
              puts "patient_link=#{patient_link}"
              patientURL=patient_link("other","reference")
              puts "PatientLink URL=#{patientURL}"
              patientID=patientURL.sub("Patient/","");

              fhir_read(:patient, patientID, client: :with_custom_headers)
              assert_response_status(200)

            end
          end
        end
      end
    end


  end
end
