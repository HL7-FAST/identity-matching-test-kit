require 'json'
require 'erb'

module IdentityMatching
    class MatchRequest

        attr_accessor( :profile_level )
        attr_reader(:last_name, :given_names, :first_name, :middle_name, :profile, :json_request, :weight, :valid_profile )

        attr_accessor( :full_name, :date_of_birth, :sex, :phone_number, :email, :street_address, :city, :state, :postal_code, 
            :passport_number, :drivers_license_number, :state_id, :master_patient_index, :medical_record_number, :insurance_member_number, 
            :insurance_subscriber_number, :social_security, :identifiers, :address, :contact_points, :hasContactPoints)

        attr_reader( :certain_matches_only )

        resource_path = File.join(__dir__, '..', '..', 'resources', 'search_parameter.json.erb')
        MATCH_PARAMETER = ERB.new(File.read(resource_path))

        def initialize (aFullName, aDOB, aSex, aPhone, aEmail, aStreetAddress, aCity, aState, aPostalCode, aPassportNumber,
            aDriversLicenseNumber, aStateID, aMasterPatientIndex, aMedicalRecordNumber, aInsuranceMemberNumber, 
            aInsuranceSubscriberNumber, aSocialSecurity, aProfileLevel, aCertainMatchesOnly, aLastName, aFirstName, aMiddleName)
            @full_name = aFullName
            @sex = aSex
            @date_of_birth = aDOB
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
            @insurance_member_number = aInsuranceMemberNumber
            @insurance_subscriber_number = aInsuranceSubscriberNumber
            @social_security = aSocialSecurity

            if !aFullName.nil? 
                get_names( aFullName.to_s)
            else
                @last_name = aLastName
                @first_name = aFirstName
                @middle_name = aMiddleName
                @given_names = []
                @given_names[0] = aFirstName if !aFirstName.nil?
                @given_names[1] = aMiddleName if !aMiddleName.nil?
            end

            @identifiers = identifiers()

            @contact_points = contact_points()

            @address = address()

            profile_url( aProfileLevel)

            certain_matches_only_to_boolean( aCertainMatchesOnly)
        end

        # for FHIR artifact id generation
        def id
            rand(9000)
        end

        def get_names( aFullName)
            @last_name = aFullName.strip.titleize.split.last
            @given_names = []
            @given_names = aFullName.strip.titleize.split
            @given_names.pop
            @first_name = @given_names.length >= 1 ? @given_names.first : nil
            @middle_name = @given_names.length > 1 ? @given_names[1] : nil
        end

        def identifiers
            ret = []
            ret << {system: "urn:oid:2.16.840.1.113883.4.3.51", code: 'DL', display: 'Drivers License', value: self.drivers_license_number} if self.drivers_license_number != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'NIIP-M', display: 'Insurance Member Number', value: self.insurance_member_number} if self.insurance_member_number != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'NIIP-S', display: 'Insurance Subscriber Number', value: self.insurance_subscriber_number} if self.insurance_subscriber_number != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'STID', display: 'State ID', value: self.state_id} if self.state_id != nil
            ret << {system: "http://hl7.org/fhir/sid/passport-USA", code: 'PPN', display: 'Passport Number', value: self.passport_number} if self.passport_number != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'MPI', display: 'Master Patient Index', value: self.master_patient_index} if self.master_patient_index != nil
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'MRN', display: 'Medical Record Number', value: self.medical_record_number} if self.medical_record_number != nil
            ret << {system: "http://hl7.org/fhir/sid/us-ssn", code: 'SS', display: 'Social Security', value: self.social_security} if self.social_security != nil
            ret
        end

        def identifiers?
            return self.drivers_license_number || self.insurance_subscriber_number || self.insurance_member_number || 
                self.state_id || self.passport_number || self.master_patient_index ||self.medical_record_number || self.social_security
        end

        def contact_points
            ret = []
            ret << {system: 'phone', value: self.phone_number, use: 'home'} if self.phone_number != nil
            ret << {system: 'email', value: self.email, use: 'home'} if self.email != nil
            ret
        end

        def contact_points?
            return self.phone_number != nil || self.email != nil ? true : false
        end

        def address
            return "#{street_address}\n#{city} #{state} #{postal_code}"
        end

        def profile_url(aProfileLevel)
            @profile_level = aProfileLevel.titleize
            @profile = case aProfileLevel
            when 'Base' then 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient'
            when 'L0' then 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L0'
            when 'L1' then 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L1'
            else ''
            end
        end

        def build_request_fhir
            @json_request = MATCH_PARAMETER.result_with_hash({model: self})
            #file  = File.read("resources/test_search_parameter.json")
            #@json_request = JSON.parse(file)
        end

        def input_weight
            @weight = 0
            if @passport_number != nil then
                @weight += 10
            end
            if (@drivers_license_number != nil || @state_id != nil) then
                @weight += 10
            end
            if ((@street_address != nil && (@postal_code != nil || (@city != nil  && @state != nil ))) ||
                @email != nil  || @phone_number != nil  || @insurance_member_number != nil || @insurance_subscribernumber != nil ||
                @social_security != nil || @master_patient_index != nil || @medical_record_number != nil) then
                @weight +=4
            end
            if @given_names != nil  && @last_name != nil  then
                @weight +=4
            end
            if @date_of_birth != nil  then
                @weight +=2
            end
            return @weight
        end

        def input_matches_profile?
            @valid_profile = false
            @valid_profile = if (@profile_level != nil && (@profile_level == 'Base' || @profile_level == 'L0'|| @profile_level == 'L1')) && (@last_name != nil || @given_names != nil) then 
                case
                    when @profile_level == 'Base' && (@identifiers != nil || @phone_number != nil || 
                        (@last_name != nil && @given_names != nil) || (@street_address != nil && @city != nil)
                        @date_of_birth != nil) then true
                    when @profile_level == 'L0' && @weight >= 10 then true
                    when @profile_level == 'L1' && @weight >= 20 then true
                    else false
                end 
                else false end
        end

        def certain_matches_only_to_boolean( aCertainMatchesOnly)
            @certain_matches_only = aCertainMatchesOnly.downcase! == 'yes' ? true : false
        end
    end
end