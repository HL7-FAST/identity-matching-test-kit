require "uri"
require "json"
require "erb"
require "net/http"
require "webmock/rspec"
require "logger"
require_relative "match_request"
require_relative "helper"
require 'active_support/core_ext/string'

module IdentityMatching
  class PatientMatchingManual < Inferno::TestGroup

    title 'Patient Matching Manual Tests'
    description 'Verify support for the $match operation required by the Patient Matching profile.'
    id :im_patient_match_manual

    input :profile_level,
      title: "IDI Profile",
      optional: false,
      type: 'radio',
      default: 'base',
      options: {
        list_options: [
          { label: 'Base', value: 'base' },
          { label: 'L0', value: 'L0' },
          { label: 'L1', value: 'L1' }
        ]}

    input :certain_matches_only,
      title: "Specify onlyCertainMatches",
      optional: false,
      type: 'radio',
      default: 'false',
      options: {
        list_options: [
          { label: 'True', value: true },
          { label: 'False', value: false }
        ]}
        
    input :param_count,
      title: "Count (matched records to return)",
      optional: true

    input :full_name,
      title: 'Name',
      optional: true
    input :date_of_birth,
      title: 'Date of Birth',
      optional: true
    input :sex,
      title: 'Sex (assigned at birth)',
      optional: true,
      type: 'radio',
      default: 'na',
      options: {
        list_options: [
          { label: 'Female', value: 'female' },
          { label: 'Male', value: 'male' },
          { label: 'Not specified', value: 'na' }
        ]}

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

    input :insurance_member_number,
      title: 'Insurance Member Identifier',
      optional: true

    input :insurance_subscriber_number,
      title: 'Insurance Subscriber Identifier',
      optional: true

    input :medical_record_number,
      title: 'Medical Record Number',
      optional: true

    input :master_patient_index,
      title: 'Master Patient Index',
      optional: true

    input :social_security,
      title: 'Social Security Number',
      optional: true

    output :last_name, :given_names, :first_name, :middle_name, :identifiers, :contact_points, :address, :input_weight, :input_conforms_to_profile

    output :response_json
    output :records_returned
    output :match_response_resource
    output :match_result

    test do
      id :patient_match_manual
      title 'Server SHALL return a bundle resource for advanced $match operation'
      description "Verify that the Patient $match resource returned from the server is a valid FHIR resource."

      
      makes_request :match_operation_manual

      run do
        baseMatchRequest = MatchRequest.new(full_name, date_of_birth, sex, phone_number, email, street_address, city, state, postal_code,
          passport_number, drivers_license_number, state_id, master_patient_index, medical_record_number, insurance_member_number,
          insurance_subscriber_number, social_security, profile_level, certain_matches_only, param_count, nil, nil, nil)

        input_weight_local = baseMatchRequest.input_weight
        input_conforms_to_profile_local = baseMatchRequest.input_matches_profile?

        output last_name: baseMatchRequest.last_name, first_name: baseMatchRequest.first_name, middle_name: baseMatchRequest.middle_name,
          given_names: baseMatchRequest.given_names, input_weight: input_weight_local, input_conforms_to_profile: input_conforms_to_profile_local

        json_request = baseMatchRequest.build_request_fhir

        #json_request = load_resource('test_queries/patient_match_search_parameter.json')
        fhir_parameter = FHIR.from_contents(json_request)

        fhir_operation('Patient/$match', body: fhir_parameter, name: :match_operation_manual)

        assert_response_status(200)

        assert_resource_type(:bundle)

        #assert_valid_bundle_entries(resource_types: 'Patient')
      end
    end

    test do
      
      id :patient_match_resource_in_bundle_manual
      title 'Bundle response for patient $match SHALL contain patient resources'
      description "Verify that Patient $match returns bundle of patient resources"

      uses_request :match_operation_manual
      
      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

        assert resource.entry.length.positive?, 'Bundle has no entries'

        entry = resource.entry.first

        assert entry.resource.is_a?(FHIR::Patient), 'The first entry in the Bundle is not a Patient'
      end
    end

    test do

      id :patient_match_manual_certain_matches
      title 'Server SHOULD validate conformance of match input element(s) for onlyCertainMatches parameter selected'
      description "Server should accept or reject request based on conformance of the match input element(s) for value of parameter onlyCertainMatches selected"

      uses_request :match_operation_manual
      
      run do
        omit_if strict == 'false' or strict === false
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'
        response_json = JSON.parse(resource.to_json)

        response_status = request.status

        baseMatchRequest = MatchRequest.new(full_name, date_of_birth, sex, phone_number, email, street_address, city, state, postal_code,
          passport_number, drivers_license_number, state_id, master_patient_index, medical_record_number, insurance_member_number,
          insurance_subscriber_number, social_security, profile_level, certain_matches_only, param_count, nil, nil, nil)

        input_weight_local = baseMatchRequest.input_weight
        input_conforms_to_profile_local = baseMatchRequest.input_matches_profile?

        last_name, first_name, middle_name, given_names, input_weight, input_conforms_to_profile = baseMatchRequest.last_name, baseMatchRequest.first_name,
          baseMatchRequest.middle_name, baseMatchRequest.given_names,  input_weight_local, input_conforms_to_profile_local

        server_accepts_response = response_status == 200 ? true : false
        meet_certain_matches = true
        meet_certain_matches = false if (certain_matches_only && (last_name.nil? || first_name.nil?))

        assert_message = case 
          when server_accepts_response == meet_certain_matches then ''
          when server_accepts_response == true && meet_certain_matches == false then
            "Server accepts a nonconformant client request with inadequate match input element(s) required for onlyCertainMatches"
          when server_accepts_response == false && meet_certain_matches == true then
            "Server rejects a conformant client request with match input element(s) required for onlyCertainMatches"
          end

        assert server_accepts_response == meet_certain_matches, assert_message
      end
    end

    test do

      id :patient_match_manual_profile_to_input
      title 'Server SHALL validate conformance of match input element(s) for the profile selected'
      description "Server will accept or reject request based on conformance of the match input element(s) for selected profile"

      uses_request :match_operation_manual
      
      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'
        response_json = JSON.parse(resource.to_json)

        response_status = request.status

        baseMatchRequest = MatchRequest.new(full_name, date_of_birth, sex, phone_number, email, street_address, city, state, postal_code,
          passport_number, drivers_license_number, state_id, master_patient_index, medical_record_number, insurance_member_number,
          insurance_subscriber_number, social_security, profile_level, certain_matches_only, param_count, nil, nil, nil)

        input_weight_local = baseMatchRequest.input_weight
        input_conforms_to_profile_local = baseMatchRequest.input_matches_profile?

        last_name, first_name, middle_name, given_names, input_weight, input_conforms_to_profile = baseMatchRequest.last_name, baseMatchRequest.first_name,
          baseMatchRequest.middle_name, baseMatchRequest.given_names,  input_weight_local, input_conforms_to_profile_local

        server_accepts_response = response_status == 200 ? true : false
        profile_level_display = profile_level == 'base' ? "(#{profile_level})" : " #{profile_level}"

        assert_message = case 
          when server_accepts_response == input_conforms_to_profile then ''
          when server_accepts_response == true && input_conforms_to_profile == false then
            "Server accepts a nonconformant client request with inadequate match input element(s) required for profile IDI Patient#{profile_level_display}"
          when server_accepts_response == false && input_conforms_to_profile == true then
            "Server rejects a conformant client request with match input element(s) required for profile IDI Patient#{profile_level_display}"
          end

        assert server_accepts_response == input_conforms_to_profile, assert_message
      end
    end

    test do

      id :search_identity_to_identity_manual
      title 'Server matching and searching SHOULD be Identity-to-Identity, not Record-to-Record'
      description %Q(
        This test will ensure the server matches on Identity-to-Identity and not Record-to-Record.
        Patient records with link of type 'replaced-by' is excluded from the search and match.
      )
      uses_request :match_operation_manual
      run do
        omit_if strict == 'false' or strict === false

        response_json = JSON.parse(resource.to_json) # resource is body from response as FHIR::Model
        entries = response_json['entry']

        skip_if entries.nil? || entries.length == 0, 'This test is skipped since Patient $match returned no patient records'

        entries.each do |entry_item|
          patient_id = entry_item['resource']['id']
          links = entry_item['resource']['link']
          if links != nil
            links.each do |link|
              link_type = link['type']
              assert(link_type != 'replaced-by', "Patient $match returned patient with 'replaced-by' link that should no longer be used")
            end
          end
        end
      end
    end

    test do

      id :patient_link_valid_manual
      title "Server SHOULD indicate linkage between records by the Patient.link field"
      description %Q(
        This test ensures linked patient records are listed in the Patient.link field.
      )

      # Use saved request/response from fhir_operation call in previous test
      uses_request :match_operation_manual

      run do
        omit_if strict == 'false' or strict === false
        response_json = JSON.parse(resource.to_json) # resource is body from response as FHIR::Model
        entries = response_json['entry']

        skip_if entries.nil? || entries.length == 0, 'This test is skipped since Patient $match returned no patient records'

        entries.each do |entry_item|
          patient_id = entry_item['resource']['id']
          links = entry_item['resource']['link']
          if links != nil
            links.each do |link|
              linked_patient_id = link['other']['reference'].gsub("Patient/", "")
              
              fhir_read(:patient, linked_patient_id)
              assert_response_status(200)
            end
          end
        end
      end
    end

    test do

      id :return_patients_score_range_output
      title "Patient Match SHALL return a score between 0 and 1 for each matched patient resource"
      description %Q(
        This test validates the bundle returned contains patient records with match score of 0.5 or above
      )

      output :matches_out_of_range
      uses_request :match_operation_manual
      run do
        response_json = JSON.parse(resource.to_json)

        entries = response_json['entry']

        skip_if entries.nil? || entries.length == 0, 'This test is skipped since Patient $match returned no patient records'

        patients_with_score_out_of_range = []

        patients_with_score_out_of_range_str = ""
        entries.each do |entry_item|
          if entry_item['search']['score'] < 0 or entry_item['search']['score'] > 1
            patients_with_score_out_of_range << {patient_id: entry_item['resource']['id'], score: entry_item['search']['score']}
            patients_with_score_out_of_range_str << "Patient #{entry_item['resource']['id']} - #{entry_item['search']['score']}; "
          end
        end

        assert patients_with_score_out_of_range.length == 0, "Server returns matched patient resources with score below zero or above one: #{patients_with_score_out_of_range_str}"

        output matches_out_of_range: patients_with_score_out_of_range_str
      end
    end

    test do

      id :return_matched_patients_score_below_point_five_manual
      title "Patient Match SHOULD only return matched patient resource with a score above 0.5"
      description %Q(
        This test validates the bundle returned contains patient records with match score of 0.5 or above
      )

      output :matches_below_point_five
      uses_request :match_operation_manual
      run do        
        omit_if strict == 'false' or strict === false
        response_json = JSON.parse(resource.to_json)

        entries = response_json['entry']

        skip_if entries.nil? || entries.length == 0, 'This test is skipped since Patient $match returned no patient records'

        patients_with_score_below_point_five = []

        patients_with_score_below_point_five_str = ""

        entries.each do |entry_item|
          if entry_item['search']['score'] < 0.5
            patients_with_score_below_point_five << {patient_id: entry_item['resource']['id'], score: entry_item['search']['score']}
            patients_with_score_below_point_five_str << "Patient #{entry_item['resource']['id']} - #{entry_item['search']['score']}; "
          end
        end

        assert patients_with_score_below_point_five.length == 0, "Server returns matches with score below 0.5: #{patients_with_score_below_point_five_str}"

        output matches_below_point_five: patients_with_score_below_point_five_str
      end
    end

    test do

      id :return_computed_score_manual
      title "Server SHOULD designate a grading of match quality using table in section 4.7 Scoring Matches & Responder's System Match Output Quality Score of the implementation guide"
      description %Q(
        This test validates scores are calculated based on the Scoring Matches table in the implementation guide 
      )

      #Initialize variables
      bMPI, bMRN, bDriversLicense, bStateID, bPassportNumber, bInsuranceMemberNumber, bInsuranceSubscriberNumber, bSocialSecurityNumber, bSSN4 = 
        false, false, false, false, false, false, false, false, false
      bLastName, bFirstName, bMiddleInitial, bMiddleName, bDateOfBirth, bSex = false, false, false, false, false, false
      bEmail, bPhone, bStreetAddress, bCity, bState, bZip = false, false, false, false, false, false
      bScoreMatches = false
      item_score, computed_score_min, computed_score_max = 0.0, 0.0, 1.0

      #Hold unmatched score records
      unmatchedRecords = []
      unmatched_records_str = ""

      uses_request :match_operation_manual

      run do
        omit_if strict == 'false' or strict === false

        response_json = JSON.parse(resource.to_json)

        response_status = request.status

        baseMatchRequest = MatchRequest.new(full_name, date_of_birth, sex, phone_number, email, street_address, city, state, postal_code,
          passport_number, drivers_license_number, state_id, master_patient_index, medical_record_number, insurance_member_number,
          insurance_subscriber_number, social_security, profile_level, certain_matches_only, param_count, nil, nil, nil)

        input_weight_local = baseMatchRequest.input_weight
        input_conforms_to_profile_local = baseMatchRequest.input_matches_profile?

        last_name, first_name, middle_name, given_names, input_weight, input_conforms_to_profile = baseMatchRequest.last_name, baseMatchRequest.first_name,
          baseMatchRequest.middle_name, baseMatchRequest.given_names,  input_weight_local, input_conforms_to_profile_local

        entries = response_json['entry']

        skip_if entries.nil? || entries.length == 0, 'This test is skipped since Patient $match returned no patient records'

        entries.each do |entry_item|
          #Reset variable values for each loop
          bMPI, bMRN, bDriversLicense, bStateID, bPassportNumber, bInsuranceMemberNumber, bInsuranceSubscriberNumber, bSocialSecurityNumber, bSSN4 = 
            false, false, false, false, false, false, false, false, false
          bLastName, bFirstName, bMiddleInitial, bMiddleName, bDateOfBirth, bSex = false, false, false, false, false, false
          bEmail, bPhone, bStreetAddress, bCity, bState, bZip = false, false, false, false, false, false
          bScoreMatches = false

          item_score, computed_score_min, computed_score_max = 0.0, 0.0, 1.0

          resource_type = entry_item['resource']['resourceType']
          patient_id = entry_item['resource']['id']
          
          assert resource_type != nil && resource_type == 'Patient', "Bundle does not have 'Patient' resource"

          if resource_type != nil && resource_type == 'Patient'
            #Get item score from resource json
            item_score = entry_item['search']['score']

            #Match identifiers
            if !passport_number.nil? || !state_id.nil? || !drivers_license_number.nil? || !insurance_member_number.nil? ||
              !insurance_member_number.nil? || !medical_record_number.nil? || !master_patient_index.nil? || !social_security.nil?
              patient_identifiers = entry_item['resource']['identifier']

              if !patient_identifiers.nil?
                patient_identifiers.each do |patient_identifier|
                  #Reset identifier variables
                  identifier_code, identifier_system, identifier_value = '', '', ''
                  identifier_coding = patient_identifier['type']['coding']

                  identifier_coding.each do |coding|
                    identifier_system = coding['system']
                    identifier_code = coding['code'] == 'SS' && social_security != nil && social_security.length == 4 ? 'SS4': coding['code']
                  end
                  identifier_value = patient_identifier['value'] 
    
                  #Check for matching identifiers
                  if identifier_value != nil && identifier_code != nil
                    case identifier_code
                      when 'DL' then bDriversLicense = true if drivers_license_number != nil && identifier_value == drivers_license_number
                      when 'STID' then bStateID = true if state_id != nil && identifier_value == state_id
                      when 'PPN' then bPassportNumber = true if passport_number != nil && identifier_value == passport_number
                      when 'SS4' then bSSN4 = true if identifier_value.length >= 4 && identifier_value[-4,4] = social_security
                      when 'SS' then bSocialSecurityNumber = true if social_security != nil && identifier_value == social_security
                      when 'MPI' then bMPI = true if master_patient_index != nil && identifier_value == master_patient_index
                      when 'MRL' then bMRN = true if medical_record_number != nil && identifier_value == medical_record_number
                      when 'NIIP-M' then bInsuranceMemberNumber = true if insurance_member_number != nil && identifier_value == insurance_member_number
                      when 'NIIP-S' then bInsuranceSubscriberNumber = true if insurance_subscriber_number != nil && identifier_value == insurance_subscriber_number
                    end
                  end
                end
              end
            end

            #Match names
            if !last_name.nil? || !first_name.nil? || !middle_name.nil?
              names = entry_item['resource']['name']
              if names != nil
                names.each do |name|
                  family = name['family']
                  bLastName = true if !family.nil? && family == last_name
                  rGivenNames = name['given']
                  bFirstName = true if !rGivenNames.empty? && rGivenNames[0] != nil && rGivenNames[0] == first_name
                  if !middle_name.nil? && rGivenNames.length > 1 && rGivenNames[1] != nil
                    bMiddleInitial = true if middle_name.length == 1 && rGivenNames[1].length == 1 && rGivenNames[1][0,1] == @middle_name
                    bMiddleName = true if middle_name.length > 1 && rGivenNames[1].length > 1 && rGivenNames[1] == middle_name
                  end
                end
              end
            end

            #Match phone number and email
            if !phone_number.nil? || !email.nil?
              aTelecom = entry_item['resource']['telecom']
              if aTelecom != nil
                aTelecom.each do |telecom|
                  telecom_system = telecom['system']
                  telecom_value = telecom['value']
                  bPhone = true if phone_number != nil && telecom_system == 'phone' && telecom_value != nil && telecom_value == phone_number
                  bEmail = true if email != nil && telecom_system == 'email' && telecom_value != nil && telecom_value == email
                end
              end
            end

            #Match address
            if !street_address.nil? || !city.nil? || !state.nil? || !postal_code.nil?
              aAddress = entry_item['resource']['address']
              if aAddress != nil
                aAddress.each do |address|
                  address_line = address['line'].flatten
                  address_city = address['city']
                  address_state = address['state']
                  address_zip = address['postalCode']
                  bStreetAddress = true if street_address != nil && address_line != nil && address_line == street_address
                  bCity = true if city != nil && address_city != nil && address_city == city
                  bState = true if state != nil && address_state != nil && address_state == state
                  bZip = true if postal_code != nil && address_zip != nil && address_zip[0,5] == postal_code[0,5]
                end
              end
            end

            #Check for matching date of birth and sex
            bDateOfBirth = true if date_of_birth != nil && entry_item['resource']['birthDate'] != nil && entry_item['resource']['birthDate'] == date_of_birth
            bSex = true if sex != nil && entry_item['resource']['gender'] != nil && entry_item['resource']['gender'] == sex

            #Calculate min and max scores for each match condition listed in 
            case
              when bMRN then computed_score_min, computed_score_max = 0.8, 1.0
              when bMPI then computed_score_min, computed_score_max = 0.8, 1.0
              when bFirstName && bLastName && bPassportNumber then computed_score_min, computed_score_max = 0.8, 1.0
              when bFirstName && bLastName && bDriversLicense then computed_score_min, computed_score_max = 0.8, 1.0
              when bFirstName && bLastName && bInsuranceMemberNumber then computed_score_min, computed_score_max = 0.8, 1.0
              when bFirstName && bLastName && bDateOfBirth && bInsuranceSubscriberNumber then computed_score_min, computed_score_max = 0.7, 0.8
              when bFirstName && bLastName && bSocialSecurityNumber then computed_score_min, computed_score_max = 0.7, 0.8
              when bFirstName && bLastName && bInsuranceSubscriberNumber then computed_score_min, computed_score_max = 0.7, 0.8
              when bFirstName && bLastName && bDateOfBirth && bStreetAddress && bZip then computed_score_min, computed_score_max = 0.7, 0.8
              when bFirstName && bLastName && bDateOfBirth && bStreetAddress && bCity && bState then computed_score_min, computed_score_max = 0.7, 0.8
              when bFirstName && bLastName && bDateOfBirth && bEmail then computed_score_min, computed_score_max = 0.7, 0.8
              when bFirstName && bLastName && bDateOfBirth && bSex && bSSN4 then computed_score_min, computed_score_max = 0.6, 0.7
              when bFirstName && bLastName && bDateOfBirth && bSex && bPhone then computed_score_min, computed_score_max = 0.6, 0.7
              when bFirstName && bLastName && bDateOfBirth && bSex && bZip then computed_score_min, computed_score_max = 0.6, 0.7
              when bFirstName && bLastName && bDateOfBirth && bSex && bMiddleName then computed_score_min, computed_score_max = 0.6, 0.7
              when bFirstName && bLastName && bDateOfBirth && bSex && bPhone then computed_score_min, computed_score_max = 0.6, 0.7
              when bFirstName && bLastName && bDateOfBirth && bSex && bMiddleInitial then computed_score_min, computed_score_max = 0.5, 0.6
              when bFirstName && bLastName && bDateOfBirth && bSex then computed_score_min, computed_score_max = 0.5, 0.6
              when bFirstName && bLastName && bDateOfBirth then computed_score_min, computed_score_max = 0.5, 0.6
              else computed_score_min, computed_score_max = 0.0, 0.5
            end

            if item_score <= computed_score_min || item_score > computed_score_max
              bScoreMatches = false
              unmatchedRecords << {patient_id: patient_id, item_score: item_score, computed_score_min: computed_score_min, computed_score_max: computed_score_max}
              unmatched_records_str << "Patient #{patient_id} has a score of #{item_score} but the expected score range is #{computed_score_min.to_s} - #{computed_score_max.to_s}; "
            end
          end
        end
        assert(bScoreMatches, "Scores for following matched records does not comply with score designation in Responder’s System Match Output Quality Score table: #{unmatched_records_str}")
      end
    end

    test do

      id :sorting_response_by_score_manual_match
      title "Response from an 'MPI' query is a bundle containing patient records SHOULD be ordered from most likely to least likely"
      description %Q(
        This test validates the bundle returned is sorted by the score from most likely to least likely
      )

      uses_request :match_operation_manual

      run do
        omit_if strict == 'false' or strict === false
        response_json = JSON.parse(resource.to_json)

        response_status = request.status

        baseMatchRequest = MatchRequest.new(full_name, date_of_birth, sex, phone_number, email, street_address, city, state, postal_code,
          passport_number, drivers_license_number, state_id, master_patient_index, medical_record_number, insurance_member_number,
          insurance_subscriber_number, social_security, profile_level, certain_matches_only, param_count, nil, nil, nil)

        input_weight_local = baseMatchRequest.input_weight
        input_conforms_to_profile_local = baseMatchRequest.input_matches_profile?

        last_name, first_name, middle_name, given_names, input_weight, input_conforms_to_profile = baseMatchRequest.last_name, baseMatchRequest.first_name,
          baseMatchRequest.middle_name, baseMatchRequest.given_names,  input_weight_local, input_conforms_to_profile_local

        entries = response_json['entry']

        skip_if entries.nil? || entries.length == 0, 'This test is skipped since Patient $match returned no patient records'

        score_returned = entries.first['search']['score']
        patient_id = entries.first['resource']['id']
        prev_score = 1.0
        previous_patient_id = ''
        is_sorted = true        

        entries.each do |entry_item|          
          patient_id = entry_item['resource']['id']
          score_returned = entry_item['search']['score']

          is_sorted = false if score_returned > prev_score

          break if !is_sorted

          previous_patient_id = patient_id
          prev_score = score_returned
        end
        
        assert( is_sorted, "Bundle containing patient records is out of order: patient #{patient_id} with score of #{score_returned} is returned after patient #{previous_patient_id} with score of #{prev_score}")
      end
    end
  end
end
