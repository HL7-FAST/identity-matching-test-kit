require 'json'
require 'erb'

module IdentityMatching
    class MatchRequest

        attr_accessor( :profile_level, :profile, :json_request)

        attr_accessor( :last_name, :given_name, :middle_name, :date_of_birth, :sex, :phone_number, :email, :street_address, :city, :state, :postal_code, 
            :passport_number, :drivers_license_number, :state_id, :master_patient_index, :medical_record_number, :insurance_number)

        attr_accessor( :certain_matches_only)

        MATCH_PARAMETER = ERB.new(File.read("resources/test_search_parameter.json.erb"))

        def initialize (aLastName, aGivenName, aMiddleName, aDOB, aSex, aPhone, aEmail, aStreetAddress, aCity, aState, aPostalCode, aPassportNumber,
            aDriversLicenseNumber, aStateID, aMasterPatientIndex, aMedicalRecordNumber, aInsuranceNumber, aProfileLevel, aCertainMatchesOnly) 
            @last_name = aLastName
            @given_name = aGivenName
            @middle_name = aMiddleName
            @sex = aSex
            @phone_number = aPhone
            @email = aEmail
            @street_address = aStreetAddress
            @city = aCity
            @state = aState
            @postal_code = aPostalCode
            @passport_number = aPassportNumber
            @drivers_license_number = aDriversLicenseNumber
            @state_id = aStateID
            @master_patient_index = aMasterPatientIndex
            @medical_record_number = aMedicalRecordNumber
            @insurance_number = aInsuranceNumber

            identifiers()

            address()

            profile_url( aProfileLevel)

            certain_matches_only_to_boolean ( aCertainMatchesOnly)
        end
=begin
        def initialize 
            @patient = Patient.new (:last_name, :given_name, :middle_name, :date_of_birth, :sex, :phone_number, :email, :street_address, :city, :state, :postal_code, 
            :passport_number, :drivers_license_number, :state_id, :master_patient_index, :medical_record_number, :insurance_number)
        end
=end

        def identifiers
            ret = []
            ret << {system: "urn:oid:2.16.840.1.113883.4.3.51", code: 'DL', display: 'Drivers License', value: self.drivers_license_number} if self.drivers_license_number != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'NIIP', display: 'Insurance Subscriber Number', value: self.insurance_number} if self.insurance_number != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'STID', display: 'State ID', value: self.state_id} if self.state_id != nil
            ret << {system: "http://hl7.org/fhir/sid/passport-USA", code: 'PPN', display: 'Passport Number', value: self.passport_number} if self.passport_number != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'MPI', display: 'Master Patient Index', value: self.master_patient_index} if self.master_patient_index != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'MRN', display: 'Medical Record Number', value: self.medical_record_number} if self.medical_record_number != nil
            ret
        end

        def identifiers?
        return self.drivers_license_number || self.insurance_subscriber_number || self.state_id || self.passport_number || self.master_patient_index ||self.medical_record_number
        end

        def address
            return "#{street_address}\n#{city} #{state} #{postal_code}"
        end

        def profile_url (aProfileLevel)
            @profile_level = aProfileLevel
            @profile = case aProfileLevel
            when 'Base' then 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient'
            when 'L0' then 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L0'
            when 'L1' then 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L1'
            else ''
            end
        end

        def build_request_fhir
            @json_request = MATCH_PARAMETER.result_with_hash({model: self})
        end

        def input_weight
            weight_value = 0;
            if !@passport_number.nil then
                weight_value += 10
            end
            if (!@drivers_license_number.nil || !@state_id.nil) then
                weight_value += 10
            end
            if ((!@street_address.nil && (!@postal_code.nil || (!@city.nil  && !@state.nil ))) ||
                !@email.nil  || !@phone_number.nil  || !@insurance_number.nil ) then
                weight_value +=4
            end
            if !@given_name.nil  && !@last_name.nil  then
                weight_value +=4
            end
            if !@date_of_birth.nil  then
                weight_value +=2
            end
            return weight_value
        end

        def input_matches_profile?
            matches_profile = false
            case 
            when profile_level = 'Base'
                matches_profile = true
            when profile_level = 'L0' && input_weight >= 10
                matches_profile = true
            when profile_level = 'L0' && input_weight >= 20
                matches_profile = true
            else 
                matches_profile = false
            end
        end

        def certain_matches_only_to_boolean (aCertainMatchesOnly)
            @certain_matches_only = aCertainMatchesOnly.downcase! == 'yes' ? true : false
        end
    end
end