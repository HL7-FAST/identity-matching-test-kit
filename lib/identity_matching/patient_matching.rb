require "uri"
require "json"
require "erb"
require "net/http"
require "webmock/rspec"
require "logger"
require_relative "match_request"
module IdentityMatching
  class PatientMatching < Inferno::TestGroup

    title 'Patient Matching Tests'
    description 'Execute a $match operation at /Patient/$match endpoint on a Master Patient Index (MPI). '
    id :patient_matching

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
      description %(
        Verify that the Patient  $match resource returned from the server is a valid FHIR resource.
      )

      input :profile_level,
        title: "Profile (Base | L0 | L1)",
        optional: false,
        default: 'L0'

      input :certain_matches_only,
        title: "Return only certain matches (Yes | No)",
        default: 'No'

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

      #logger= Logger.new(STDOUT)

      run do
          @match_request = MatchRequest.new( last_name, given_name, middle_name, date_of_birth, sex, phone_number, email, street_address, city, state, postal_code,
            passport_number, drivers_license_number, state_id, master_patient_index, medical_record_number, insurance_number, profile_level, certain_matches_only)

          #puts "Driver's License: #{@match_request.drivers_license_number}"
          #puts "Identifiers: #{@match_request.identifiers}"
          #puts "DEBUG: Profile: #{@match_request.profile}"
          #puts "Certain Matches Only: #{@match_request.certain_matches_only}"

          resource_path = File.join( __dir__, '..', '..', 'resources', 'search_parameter.json.erb')
          match_parameter = ERB.new(File.read(resource_path))
          @json_request = match_parameter.result_with_hash({model: @match_request})
          puts "DEBUG: #{@json_request}"

      end
    end



    test do
      input :response_json
      title 'Patient match - determines whether or not the $match function returns every valid record'
      description %Q(
        Match output SHOULD contain every record of every candidate identity, subject to volume limits
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
        assert resource.id == patient.id, "Requested resource with id #{patient.id}, received resource with id #{resource.id}"

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

        assert_valid_resource({ :profile_url => 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient'})
        skip
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
      input :access_token;
      input :search_json ,
        type: 'textarea'



      run do
        body = JSON[search_json]
        fhir_operation("Patient/$match", body: body, client: :default, name: :match, headers: { 'Content-Type'=>'application/fhir+json' })
        assert_response_status(401)

      end
    end

    test do
      title 'Patient match is valid'
      description %(
      Verify that the Patient  $match resource returned from the server is a valid FHIR resource.
      )

      input 	:search_json ,
            type: 'textarea'
      output 	:custom_headers
      output 	:response_json
      # Named requests can be used by other tests
      makes_request :match


      run do
        body = JSON[search_json]
        fhir_operation("Patient/$match", body: body, client: :with_custom_headers, name: :match, headers: { 'Content-Type'=>'application/fhir+json' })

        responseBody= response[:body]

        output response_json: response[:body]
        assert_response_status(200)
        assert_valid_bundle_entries(resource_types: 'Patient')

      end
    end

    test do
      input :expectedResultCnt
      input :response_json
      output :numberOfRecordsReturned
      title 'Patient match - determines whether or not the $match function returns every valid record'
      description %(Match output SHOULD contain every record of every candidate identity, subject to volume limits
      )
      uses_request :match
      run do

        #puts response_json
        response = JSON[response_json]
        assert_valid_json(response_json, message = "Invalid JSON response received - expected: #{expectedResultCnt} - received: #{numberOfRecordsReturned}")
        numberOfRecordsReturned = response['total'] 
        puts "number of records returned in bundle ---- #{numberOfRecordsReturned} "
        puts "number of records expected in bundle ---- #{expectedResultCnt} "
        assert numberOfRecordsReturned.to_i() == expectedResultCnt.to_i(), "Incorrect Number of Records returned"
        output numberOfRecordsReturned: numberOfRecordsReturned

      end

    end

    test do
      input :expectedResultCnt
      input :response_json
      title 'Determine whether or not the records are sorted by ID and Score'
      description %(Match output SHOULD return records sorted by score      )
      uses_request :match
      run do

        i =0
        curr_id=0
        prev_id=0
        curr_score=0
        prev_score=0
        is_sorted=true

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
      input :response_json
      title 'Determine whether or not  the patient.link field references an underlying patient'
      description %(Determine whether or not  the patient.link field references an underlying patient    )

      run do

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
