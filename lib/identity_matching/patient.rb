module IdentityMatching
    class Patient
        attr_accessor( :last_name, :given_name, :middle_name, :date_of_birth, :sex, :phone_number, :email, :street_address, :city, :state, :postal_code, 
            :passport_number, :drivers_license_number, :state_id, :master_patient_index, :medical_record_number, :insurance_subscriber_number)
        attr_reader (:identifier_code, :identifier_system, :identifier_display, :identifier_value)

        def initialize (aLastName, aGivenName, aMiddleName, aDOB, aPhone, aEmail, aStreetAddress, aCity, aState, aPostalCode, aPassportNumber,
            aDriversLicenseNumber, aStateID, aMasterPatientIndex, aMedicalRecordNumber, aInsuranceSubscriberNumber) 
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
            @state_id = astateid
            @master_patient_index = aMasterPatientIndex
            @medical_record_number = aMedicalRecordNumber
            @insurance_subscriber_number = aInsuranceSubscriberNumber

            identifiers()

            address()
        end

        def identifiers
            ret = []
            ret << {system: IDENTIFIER_SYSTEM, code: 'DL', display: 'Drivers License', value: self.drivers_license_number} if self.has? :drivers_license_number
            ret << {system: IDENTIFIER_SYSTEM, code: 'NIIP', display: 'Insurance Subscriber Number', value: self.insurance_subscriber_number} if self.has? :insurance_subscriber_number
            ret << {system: "http://terminology.hl7.org/CodeSystem/v2-0203", code: 'STID', display: 'State ID', value: self.state_id} if self.has? :state_id
            ret << {system: IDENTIFIER_SYSTEM, code: 'PPN', display: 'Passport Number', value: self.passport_number} if self.has? :passport_number
            ret << {system: IDENTIFIER_SYSTEM, code: 'MPI', display: 'Master Patient Index', value: self.master_patient_index} if self.has? :master_patient_index
            ret << {system: IDENTIFIER_SYSTEM, code: 'MRN', display: 'Medical Record Number', value: self.medical_record_number} if self.has? :medical_record_number
            ret
        end

        def identifiers?
        return self.drivers_license_number || self.insurance_subscriber_number || self.state_id || self.passport_number || self.master_patient_index ||self.medical_record_number
        end

        def address
        return "#{street_address}\n#{city} #{state} #{zipcode}"
        end
    end
end
