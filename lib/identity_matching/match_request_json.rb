require 'json'
require 'erb'

module IdentityMatching

	# helper class for MatchOperation TestGroup
    class MatchRequestJSON
        attr_accessor( :json_request)

        attr_reader( :patient_resource, :names, :last_name, :given_names, :first_name, :middle_name, :full_name, :profile_level, :profile, :weight, :valid_profile,
        :date_of_birth,:sex, :phone_number, :email, :street_address, :city, :state, :postal_code, :passport_number, :drivers_license_number,
        :state_id, :master_patient_index, :medical_record_number, :insurance_member_number, :insurance_subscriber_number, :social_security, 
        :identifiers, :address, :contact_points, :hasContactPoints, :param_count, :certain_matches_only)

        def initialize (aJSONRequest)
            @json_request = JSON.parse(aJSONRequest)

            parameters = @json_request['parameter']

            if !parameters.nil?
                parameters.each do |parameter|
                    parameter_name = parameter['name']

                    case parameter_name
                    when 'resource' then
                        @patient_resource = parameter['resource']
           
                        profile_details( @patient_resource)
                        get_names( @patient_resource)
                        get_identifiers( @patient_resource)
                        get_telecom( @patient_resource)
                        get_addresses( @patient_resource)

                        @date_of_birth = @patient_resource['birthDate']
                        @sex = @patient_resource['gender']

                        @weight = input_weight()
                        @valid_profile = input_matches_profile?
                    when 'count' then
                        @param_count = parameter['valueInteger']
                    when 'onlyCertainMatches' then
                        @certain_matches_only = parameter['valueBoolean']
                    end
                end
            end
        end

        def profile_details( aPatientRequest)
            profiles = aPatientRequest['meta']['profile']
            @profile, @profile_level = '', ''
            if !profiles.nil?
                profiles.each do |profile_local|
                    if profile_local == 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient' ||
                        profile_local == 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L0' ||
                        profile_local == 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L1'
                        @profile = profile_local
                        @profile_level = case @profile
                            when 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient' then 'base'
                            when 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L0' then 'L0'
                            when 'http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient-L1' then 'L1'
                        end
                    end
                end
            end
        end

        def get_names( aPatientRequest)
            @names = aPatientRequest['name']
            if !@names.nil?
                names.each do |name|
                    @last_name = name['family']
                    @given_names = name['given']
                    if !@given_names.nil?
                        @first_name = @given_names[0]
                        @middle_name = @given_names[1] if @given_names.length > 1
                    end
                    @full_name = ''
                    @full_name << @first_name + ' ' if !@first_name.nil?
                    @full_name << @middle_name + ' ' if !@middle_name.nil?
                    @full_name << @last_name if !@last_name.nil?
                end
            end
        end

        def get_identifiers( aPatientRequest)
            patient_identifiers = aPatientRequest['identifier']
            @identifiers = []
            if !patient_identifiers.nil?
                patient_identifiers.each do |patient_identifier|
                    #Reset variables
                    identifier_system, identifier_code, identifier_display, identifier_value = '', '', '', ''
                    identifier_coding = patient_identifier['type']['coding']
                    if !identifier_coding.nil?
                        identifier_coding.each do |coding|
                            identifier_system = coding['system']
                            identifier_code = coding['code']
                            identifier_display = coding['display']
                        end
                    end
                    identifier_value = patient_identifier['value']
                    
                    #Populate identifier array
                    @identifiers << {system: identifier_system, code: identifier_code, display: identifier_display, value: identifier_value}
                    
                    #Check for matching identifiers
                    if identifier_value != nil && identifier_code != nil
                        case identifier_code
                          when 'DL' then @drivers_license_number = identifier_value
                          when 'STID' then @state_id = identifier_value
                          when 'PPN' then @passport_number = identifier_value
                          when 'SS' then @social_security = identifier_value
                          when 'MPI' then @master_patient_index = identifier_value
                          when 'MRL' then @medical_record_number = identifier_value
                          when 'NIIP-M' then @insurance_member_number = identifier_value
                          when 'NIIP-S' then @insurance_subscriber_number = identifier_value
                        end
                    end
                end
            end
        end

        def get_telecom( aPatientRequest)
            @contact_points = [], @phone_number = nil, @email = nil
            patient_telecom = aPatientRequest['telecom']
            if !patient_telecom.nil?
                patient_telecom.each do |telecom|
                    telecom_system = telecom['system']
                    telecom_value = telecom['value']
                    telecom_use = if telecom['use'].nil? then 'home' else telecom['use'] end

                    #Populate telecom array
                    @contact_points << {system: telecom_system, value: telecom_value, use: telecom_use}

                    if telecom_system != nil && telecom_value != nil
                        case telecom_system
                        when 'phone' then @phone_number = telecom_value
                        when 'email' then @email = telecom_value
                        end
                    end
                end
            end
        end

        def get_addresses( aPatientRequest)
            @address = []
            patient_address = aPatientRequest['address']
            if !patient_address.nil?
                patient_address.each do |address|
                    @street_address = address['line'].join("")
                    @city = address['city']
                    @state = address['state']
                    @postal_code = address['postalCode']
                    @address << {line: @street_address, city: @city, state: @state, postal_code: @postal_code}
                end
            end
        end

        def identifiers?
        return self.drivers_license_number || self.state_id  || self.insurance_subscriber_number|| self.insurance_member_number
            self.passport_number || self.master_patient_index ||self.medical_record_number ||self.medical_record_number
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
    end
end
