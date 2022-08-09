require "uri"
require "json"
require "erb"
require "net/http"
require "webmock/rspec"
require "logger"
require_relative "match_request"

module IdentityMatching

  class MatchOperation < Inferno::TestGroup
    #include MatchRequest

    title 'Match Operation Tests'
    description 'Verify support for the $match operation required by the Patient Matching profile.'
    id :im_patient_match_operation

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

      # create a "default" client for a group

      logger= Logger.new(STDOUT)
      # create a named client for a group

      run do
          @match_request = MatchRequest.new( last_name, given_name, middle_name, date_of_birth, sex, phone_number, email, street_address, city, state, postal_code,
            passport_number, drivers_license_number, state_id, master_patient_index, medical_record_number, insurance_number, profile_level, certain_matches_only)

          #puts "Driver's License: #{@match_request.drivers_license_number}"
          #puts "Identifiers: #{@match_request.identifiers}"
          puts "DEBUG: Profile: #{@match_request.profile}"
          #puts "Certain Matches Only: #{@match_request.certain_matches_only}"

		  resource_path = File.join( __dir__, '..', '..', 'resources', 'search_parameter.json.erb')
          match_parameter = ERB.new(File.read(resource_path))
          @json_request = match_parameter.result_with_hash({model: @match_request})
		  puts "DEBUG: #{@json_request}"

#          file  = File.read("resources/test_search_parameter.json.erb")
#          @json_request = JSON.parse(file)
#
#          fhir_operation ("Patient/$match", body: body, client: :default,
#            name: match_operation, headers: { 'Content-Type': 'application/fhir+json' })

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

test do
  title 'Test whether it is possible to gain access to patient data without authenticating'
  description %(Test whether it is possible to gain access to patient data without authenticating - 
  This Test attempts to make a $match api call  without providing the authentication credentials)  
  input :access_token;
  input :search_json ,
  type: 'textarea'



  run do
    body = JSON[search_json]
      fhir_operation("Patient/$match", body: body, client: :default, name: :match, headers: { 'Content-Type': 'application/fhir+json' })
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



  logger= Logger.new(STDOUT)
  # create a named client for a group

#			  fhir_client  do
#				url :url
#			  end

  run do
    body = JSON[search_json]
    #custom_headers={'Content-Type': 'application/fhir+json', 'Authorization': 'Bearer ' +access_token};
    #fhir_operation("Patient/$match", body: body, client: :default, name: :match, headers:  custom_headers)
    fhir_operation("Patient/$match", body: body, client: :with_custom_headers, name: :match, headers: { 'Content-Type': 'application/fhir+json' })

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

    #output :response_json response
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
      puts "#{item}"
      puts "#{item} entry: #{item["entry"]}" 

      curr_score=item.dig("resource","score")
      curr_id=item.dig("resource","id")
      #puts  "Current Patient ID=#{curr_id}  Patient Score=#{curr_score}"
      #puts  "Current Patient ID=#{curr_id} "
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

test do
  input :response_json
  title 'Determine whether the weighted score of the returned patient resource is in compliance
  with the level of assurance (e.g., IDI Patient 1, IDI Patient 2, etc ) asserted by the transmitting  party.'
  description %(Match output SHOULD return records sorted by score      )

  output :results
  uses_request :match
  run do
      puts "*********************  Get Response Object ****************"
      #responseJSON = JSON.parse(response_json)
      responseJSON=JSON[response_json]
      #responseJSON=JSON.parse(tmp)
      idi_patient_profile="http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient"
      idi_patient_l0_profile="http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L0" 
      idi_patient_l1_profile="http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L1" 
      results=""
      responseJSON["entry"].each do |entry|
          weighted_score= 0

          # Get Patient Name, Address, DOB and telecom info

          resourceID=entry.dig("resource","id")
          givenName=entry.dig("resource","name",0,"given",0)
          familyName=entry.dig("resource","name",0,"family") 
          homeAddressLine=""
          homeAddressCity=""
          emailAddress=""
          phoneNumber=""
          ppn_id=""
          other_id=""
          dl_id=""
          stid_id=""
          photo=""
          photo=entry.dig("resource","photo")
          telecomArray=[]

          telecomArray=entry.dig("resource","telecom")
          puts ("telecomArray = #{telecomArray}")
          if (  !telecomArray.nil?  )
            telecomArray.each do |telecom|
              if telecom["system"]="phone"
                phoneNumber=telecom["value"]
              elsif telecom["system"]="email"
                emailAddress=telecom["value"]
              end
            end # end do
          end #end if

          birthDate=entry.dig("birthDate")
          identifierList= entry.dig("resource","identifier")

          #get Patient Address Info
          addressList= entry["address"]
          if ( !addressList.nil?)
            addressList.each do |address|
              if  (address["use"]="home" and address["line"] != "" and address["city"] != "" )
                homeAddressLine=address["line"]
                homehomeAddressCity=address["city"]
              end
            end #end do
          end #end if

          # Get Patient Identifiers
          patientID=""
          if ( !identifierList.nil? )
            identifierList.each do |identifier|

              thisID=identifier.dig("type","text")
              codingArray=identifier.dig("type","coding")
              if ( !codingArray.nil? )
                codingArray.each do |coding|
                  code=coding["code"]
                  if code == "PPN"
                    ppn_id=thisID
                    patientID=thisID
                  elsif   ( code == "STID" )
                    stid_id=thisID
                    patientID=thisID
                  elsif ( code== "DL")
                    dl_id=thisID
                    patientID=thisID
                  else
                    other_id=thisID
                    patientID=thisID
                  end
                end #end do
              end #end if
            end	#end do
          end #end if ( identifierList != :null )

          profileList= entry.dig("resource","meta","profile")
          if ( !profileList.nil? )
            idi_patient_l1=false
            idi_patient = false
            idi_patient_l0=false

            profileList.each do |profile|
              puts "****profile=#{profile}"
              puts ("Patient record Id = #{resourceID} ****")
              # Only validate Patient and Condition bundle entries. Validate Patient
              # resources against the given profile, and Codition resources against the
              # base FHIR Condition resource.


              if profile == idi_patient_profile

                if ( (patientID!="" or emailAddress != ""  or phoneNumber != "" ) or  ( givenName!=""  && familyName!="" ) or
                  ( homeAddressLine!="" && homehomeAddressCity!="" ) or brithDate!="" )
                  results+="patient with Resource ID of #{resourceID} passed IDI_PATIENT Level Testing <br>"
                  idi_patient=true
                end
                output results: results
                assert idi_patient == true

              elsif profile == idi_patient_l0_profile
                if ( ppn_id !="")
                  weighted_score=10
                end
                if ( dl_id != ""  or stid_id != "" )
                  weighted_score=weighted_score + 10
                end
                if ( (homeAddressLine != "" and homehomeAddressCity != "" ) or 
                  ( other_id != "" ) or  
                  ( emailAddress != "" or phoneNumber != "" or photo!= "" ))
                  weighted_score = weighted_score + 4
                end 

                if ( familyName != "" && givenName != "")
                  weighted_score = weighted_score + 4
                end
                if ( birthDate != "")
                  weighted_score += 2
                end
                if weighted_score >= 10 
                  idi_patient_l0=true 
                  results+="Patient with Resource ID of #{resourceID} passed IDI_PATIENT_0 Level Testing  - weighted score= #{weighted_score}     - "
                end
                output results: results 
                assert idi_patient_l0 == true

              elsif  profile == idi_patient_l1_profile 
                if ( ppn_id !="")
                  weighted_score=10
                end
                if ( dl_id != ""  or stid_id != "" )
                  weighted_score=weighted_score + 10
                end
                if ( (homeAddressLine!= "" and homehomeAddressCity != "" ) or
                  ( other_id !="" ) or
                  ( emailAddress != "" or phoneNumber != "" or photo!= "" ))
                    weighted_score = weighted_score + 4
                end

                if ( familyName != "" && givenName != "")
                  weighted_score = weighted_score + 4
                end
                if ( birthDate != "")
                  weighted_score += 2
                end
                puts ("Patient with Resource ID of #{resourceID}  IDI_PATIENT_1 Level Testing - weighted score= #{weighted_score}        -  ")

                if weighted_score >= 20
                  idi_patient_l1=true
                  results+="Patient with Resource ID of #{resourceID} passed IDI_PATIENT_1 Level Testing - weighted score= #{weighted_score}    -  "

                end
                puts ( "idi_patient_l1=#{idi_patient_l1}")
                output results: results
                assert idi_patient_l1 == true
              else
                results+="Patient with Resource ID of #{resourceID} contains an invalid Identification Level #{profile}"

              end
            end

      end
      output results

  end

end
end
=end
  end
end
