require "uri"
require "json"
require "erb"
require "net/http"
require "webmock/rspec"
require "logger"
require_relative "match_request"
require 'active_support/core_ext/string'

module IdentityMatching
    class MatchInput < Inferno::Test
        def generate_match_input_tests( aParam, aProfileLevel, aPositiveTest )
            aFullName = nil
            aSex = nil
            aState = nil
            aPostalCode = nil
            aStateID = nil
            aMasterPatientIndex = nil
            aInsuranceMemberNumber = nil
            aInsuranceSubscriberNumber = nil
            aSocialSecurity = nil
            aCertainMatchesOnly = 'no'
            aMiddleName = nil
      
            #Create tests based on parameters sent
            aParams.each do |parameter|
              test do
                test_description = parameter[:test_description].to_s
                bLastName = parameter[:bLastName]
                bFirstName = parameter[:bFirstName]
                bDOB = parameter[:bDOB]
                bIdentifier = parameter[:bIdentifier]
                bTelecom = parameter[:bTelecom]
                bAddress = parameter[:bAddress]
                bPPN = parameter[:bPPN]
                bDL = parameter[:bDL]
                bEmail = parameter[:bEmail]
      
                if aPositiveTest
                  aTestID = "minimum"
                  aTitle = ""
                  aDescription = ""
                else
                  aTestID = "insufficient"
                  aTitle = "NOT"
                  aDescription = "no"
                end
        
                test_id = ("patient_match_" + aProfileLevel + "_profile_" + aTestID + "_parameters_" + test_description.parameterize.underscore).to_sym
                id test_id
                title "Patient match for profile IDI Patient " + aProfileLevel + " with " + test_description + " SHOULD " + aTitle + " return data"
                description "Verify that the Patient $match returns " + aDescription + " data for profile IDI Patient " + aProfileLevel + " with " + test_description
      
                run do
                  aDOB = bDOB ? '1991-12-31' : nil
                  aPhone = bTelecom ? '555-555-5555' : nil
                  aStreetAddress = bAddress ? '135 Dolly Madison Pkwy' : nil
                  aCity = bAddress ? 'McLean' : nil
                  aMedicalRecordNumber = bIdentifier ? 'MS12121212' : nil
                  aLastName = bLastName ? 'Doe' : nil
                  aFirstName = bFirstName ? 'Jane' : nil
                  aPassportNumber = bPPN ? 'US53535353' : nil
                  aDriversLicenseNumber = bDL ? '999199912' : nil
                  aEmail = bEmail ? 'jane_doe@email.com' : nil
      
                  puts "aDOB: #{aDOB}; aPhone: #{aPhone}; aStreetAddress: #{aStreetAddress}; aCity: #{aCity}; aPassportNumber: #{aPassportNumber}; 
                    aLastName: #{aLastName}; aFirstName: #{aFirstName};"
              
                  baseMatchRequest = MatchRequest.new(aFullName, aDOB, aSex, aPhone, aEmail, aStreetAddress, aCity, aState, aPostalCode, aPassportNumber,
                    aDriversLicenseNumber, aStateID, aMasterPatientIndex, aMedicalRecordNumber, aInsuranceMemberNumber, aInsuranceSubscriberNumber, aSocialSecurity, 
                    aProfileLevel, aCertainMatchesOnly, aLastName, aFirstName, aMiddleName)
      
                  puts "Last Name: #{baseMatchRequest.last_name}"
                  puts "First Name: #{baseMatchRequest.first_name}"
                  puts "Middle Name: #{baseMatchRequest.middle_name}"
                  puts "Date of Birth: #{baseMatchRequest.date_of_birth}"
                  puts "Phone Number: #{baseMatchRequest.phone_number}"
                  puts "Email: #{baseMatchRequest.email}"
                  puts "Street Address: #{baseMatchRequest.street_address}"
                  puts "City: #{baseMatchRequest.city}"
                  puts "Passport Number: #{baseMatchRequest.passport_number}"
                  puts "Driver's License: #{baseMatchRequest.drivers_license_number}"
                  puts "Medical Record Number: #{baseMatchRequest.medical_record_number}"
                  puts "Identifiers: #{baseMatchRequest.identifiers}"
                  puts "Identifiers?: #{baseMatchRequest.identifiers?}"
      
                  json_request = baseMatchRequest.build_request_fhir
                  puts "======================="
                  puts "DEBUG: #{json_request}"
                  puts "======================="
                  fhir_parameter = FHIR.from_contents(json_request)
      
                  fhir_operation('Patient/$match', body: fhir_parameter)
      
                  if aPositiveTest
                    assert_response_status(200)
      
                    assert_resource_type(:bundle)
                  else
                    response_status = request.status
      
                    assert(response_status != 200, "FHIR endpoint returns results for profile IDI Patient " + aProfileLevel + 
                      " when input parameters are insuffiencient to not satisfy minimum requirements")
                  end
                end
              end
            end
          end
    end
end