require "uri"
require "json"
require "erb"
require "net/http"
require "webmock/rspec"
require "logger"
require_relative "match_request"
require_relative "match_request_json"
require_relative "helper"
require 'active_support/core_ext/string'

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

    def response_json
      if !!resource # may get defined by uses_request
        return resource.to_json
      else
        patient = FHIR.from_contents( load_resource('test_patients/patient1.json') )
        return FHIR::Bundle.new({'id' => 1, 'type' => 'searchset', 'entry' => [], 'total' => 0})
      end
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
      title 'Server SHALL restrict access without authenticating'
      description %(Test whether it is possible to gain access to patient data without authenticating -
      This Test attempts to make a $match api call without providing the authentication credentials)

      run do
        body = JSON[search_json]
        fhir_operation("Patient/$match", body: body, client: :default, name: :match, headers: { 'Content-Type'=>'application/fhir+json' })
        #Reference Implementation does not support authentication at this time
        #assert_response_status(401)
        info "This test is an automatic pass, please see ABOUT."
        pass
      end
    end

    test do
      id :patient_match_base
      title 'Server SHALL return bundle response for simple $match operation'
      description "Verify that the Patient $match resource returned from the server is a valid FHIR resource."

      makes_request :match_operation

      run do
        json_request = load_resource('test_queries/simple_match_base.json')
        fhir_parameter = FHIR.from_contents(json_request)

        fhir_operation('Patient/$match', body: fhir_parameter, name: :match_operation)

        assert_response_status(200)

        assert_resource_type(:bundle)

        #assert_valid_bundle_entries(resource_types: 'Patient')
      end
    end

    test do
      id :patient_match_no_profile
      title 'Patient match SHALL support minimum requirement that the IDI Patient(base) profile be used - check for missing profile'
      description "Verify that the Patient $match returns no response when the profile is missing"

      run do
          json_request = load_resource('test_queries/patient_match_no_profile.json')
          fhir_parameter = FHIR.from_contents(json_request)

          fhir_operation('Patient/$match', body: fhir_parameter)

          response_status = request.status

          assert(response_status != 200, "FHIR endpoint returns response when the profile is not specified")
      end
    end

    test do
      id :patient_match_invalid_profile
      title 'Patient match SHALL support minimum requirement that the IDI Patient(base) profile be used - check for invalid profile'
      description "Verify that the Patient $match returns no response when the profile is invalid"

      run do
          json_request = load_resource('test_queries/patient_match_invalid_profile.json')
          fhir_parameter = FHIR.from_contents(json_request)

          fhir_operation('Patient/$match', body: fhir_parameter)

          response_status = request.status

          assert(response_status != 200, "FHIR endpoint returns response although the profile specified is not valid")
      end
    end

    test do
      id :patient_match_certain_matches_no_first_name
      title 'Server SHOULD return no response when onlyCertainMatches is true and given name is missing'
      description "Verify that the Patient $match returns no response when onlyCertainMatches is true and given name is missing"

      run do
        omit_if strict == 'false' or strict === false
        records_returned = 0
        json_request = load_resource('test_queries/patient_match_certain_matches_no_first_name.json')
        fhir_parameter = FHIR.from_contents(json_request)

        fhir_operation('Patient/$match', body: fhir_parameter)

        response_status = request.status
        records_returned = resource.total

        assert(response_status != 200 || records_returned == 0, "FHIR endpoint returns response although onlyCertainMatches is true and first name is missing")
      end
    end

    test do
      id :patient_match_certain_matches_false_no_first_name
      title 'Server SHOULD return a response when onlyCertainMatches is false and given name is missing'
      description "Verify that the Patient $match returns a response when onlyCertainMatches is false and given name is missing"

      run do
        omit_if strict == 'false' or strict === false
        json_request = load_resource('test_queries/patient_match_certain_matches_false_no_first_name.json')
        fhir_parameter = FHIR.from_contents(json_request)

        fhir_operation('Patient/$match', body: fhir_parameter)

        assert_response_status(200)
      end
    end

    test do
      id :patient_match_certain_matches_no_last_name
      title 'Server SHOULD return no response when onlyCertainMatches is true and family name is missing'
      description "Verify that the Patient $match returns no response when onlyCertainMatches is true and family name is missing"

      run do
        omit_if strict == 'false' or strict === false
        records_returned = 0
        json_request = load_resource('test_queries/patient_match_certain_matches_no_last_name.json')
        fhir_parameter = FHIR.from_contents(json_request)

        fhir_operation('Patient/$match', body: fhir_parameter)

        response_status = request.status
        records_returned = resource.total

        assert(response_status != 200 || records_returned == 0, "FHIR endpoint returns response although onlyCertainMatches is true and last name is missing")
      end
    end

    test do
      id :patient_match_certain_matches_false_no_last_name
      title 'Server SHOULD return a response when onlyCertainMatches is false and family name is missing'
      description "Verify that the Patient $match returns a response when onlyCertainMatches is false and family name is missing"

      run do
        omit_if strict == 'false' or strict === false
        json_request = load_resource('test_queries/patient_match_certain_matches_false_no_last_name.json')
        fhir_parameter = FHIR.from_contents(json_request)

        fhir_operation('Patient/$match', body: fhir_parameter)

        assert_response_status(200)
      end
    end

    test do
      id :patient_match_return_count_2
      title 'Servers SHALL return count of records specified'
      description "Verify that the Patient $match returns only 2 records when 'count' parameter set to 2"

      run do
          json_request = load_resource('test_queries/patient_match_count_parameter.json')
          fhir_parameter = FHIR.from_contents(json_request)

          fhir_operation('Patient/$match', body: fhir_parameter)

          records_returned = resource.total

          assert_response_status(200)
          assert(records_returned <= 2, "Patient $match returns more records (#{records_returned}) than specified (2)")
      end
    end

    #Test cases to validate input parameters passed are valid
    aFullName = nil
    aSex = nil
    aEmail = nil
    aState = nil
    aPostalCode = nil
    aDriversLicenseNumber = nil
    aMasterPatientIndex = nil
    aMedicalRecordNumber = nil
    aInsuranceMemberNumber = nil
    aInsuranceSubscriberNumber = nil
    aSocialSecurity = nil
    aCertainMatchesOnly = false
    aCount = nil
    aMiddleName = nil

    #Input profile Base validation    
    aProfileLevel = 'base'
    
    #Input parameters not sufficient to return data / Input parameters minimum required to return data
    aPositiveTest = true

    parameters = []

    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'identifier', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: true, bTelecom: false, bAddress: false, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'telecom (phone number)', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: true, bAddress: false, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'telecom (email)', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: true}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'family name', bLastName: true, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'given name', bLastName: false, bFirstName: true, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address line', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: true, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'city', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'address (address line and city)', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'birth date', bLastName: false, bFirstName: false, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: false, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}

    #Input profile L0 validation    
    aProfileLevel = 'L0'
    #Input parameters not sufficient to return data / Input parameters minimum required to return data
    aPositiveTest = true
    
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'passport number', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: true, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "driver's license", bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: true, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'state id', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: true, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "driver's license and state id", bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: true, bSTID: true, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city)', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'identifier', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: true, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'telecom (phone number)', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: true, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'telecom (email)', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: true}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'birth date', bLastName: false, bFirstName: false, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: false, bCity: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city) and family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'identifier and family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: true, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'telecom (phone number) and family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: false, bTelecom: true, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'telecom (email) and family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: true}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city), identifier, and family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: true, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city), identifier, telecom (phone number), and family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: true, bTelecom: true, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city), identifier, telecom (phone number), telecom (email), and family and given names', bLastName: true, bFirstName: true, bDOB: false, bIdentifier: true, bTelecom: true, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: true}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'address (address line and city), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'identifier, family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: true, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'telecom (phone number), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: true, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'telecom (email), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: true}

    #Input profile L1 validation    
    aProfileLevel = 'L1'
    #Input parameters not sufficient to return data / Input parameters minimum required to return data
    aPositiveTest = true

    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'passport number', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: true, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: "driver's license", bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: true, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'state id', bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: true, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city), identifier, family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: true, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city), identifier, telecom (phone number), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: true, bTelecom: true, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'address (address line and city), identifier, telecom (phone number), telecom (email), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: true, bTelecom: true, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: false, bEmail: true}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'identifier, family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: true, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'telecom (phone number), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: true, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: !aPositiveTest, test_description: 'telecom (email), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: false, bEmail: true}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "passport number and driver's license", bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: true, bDL: true, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "passport number and state id", bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: true, bDL: false, bSTID: true, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "passport number, driver's license, and state id", bLastName: false, bFirstName: false, bDOB: false, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: true, bDL: true, bSTID: true, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'passport number, address (address line and city), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: true, bCity: true, bPPN: true, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'passport number, identifier, family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: true, bTelecom: false, bAddress: false, bPPN: false, bDL: true, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'passport number, telecom (phone number), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: true, bAddress: false, bPPN: true, bDL: false, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'passport number, telecom (email), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: true, bDL: false, bSTID: false, bEmail: true}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "driver's license, address (address line and city), family and given names, and birth date", bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: true, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "driver's license, identifier, family and given names, and birth date", bLastName: true, bFirstName: true, bDOB: true, bIdentifier: true, bTelecom: false, bAddress: false, bPPN: false, bDL: true, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "driver's license, telecom (phone number), family and given names, and birth date", bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: true, bAddress: false, bPPN: false, bDL: true, bSTID: false, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: "driver's license, telecom (email), family and given names, and birth date", bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: true, bSTID: false, bEmail: true}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'state id, address (address line and city), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: true, bCity: true, bPPN: false, bDL: false, bSTID: true, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'state id, identifier, family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: true, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: true, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'state id, telecom (phone number), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: true, bAddress: false, bPPN: false, bDL: false, bSTID: true, bEmail: false}
    parameters << {profile_level: aProfileLevel, test_type: aPositiveTest, test_description: 'state id, telecom (email), family and given names, and birth date', bLastName: true, bFirstName: true, bDOB: true, bIdentifier: false, bTelecom: false, bAddress: false, bPPN: false, bDL: false, bSTID: true, bEmail: true}
   
    #generate_match_input_tests(parameters, aProfileLevel, aPositiveTest)
    #Create tests for base profile with minimum parameter specified that should return results
    parameters.each do |parameter|
      test do
        profile_level = parameter[:profile_level].to_s
        profile_level_display = profile_level == 'base' ? "(#{profile_level})" : " #{profile_level}"
        positive_test = parameter[:test_type]
        test_description = parameter[:test_description].to_s
        bLastName = parameter[:bLastName]
        bFirstName = parameter[:bFirstName]
        bDOB = parameter[:bDOB]
        bIdentifier = parameter[:bIdentifier]
        bTelecom = parameter[:bTelecom]
        bAddress = parameter[:bAddress]
        bCity = parameter[:bCity]
        bPPN = parameter[:bPPN]
        bDL = parameter[:bDL]
        bSTID = parameter[:bSTID]
        bEmail = parameter[:bEmail]

        if positive_test
          aServerStatus = "accept"
          aTitle = ""
          aTitle2 = ""
          aAdditionalDescription = ""
        else
          aServerStatus = "reject"
          aTitle = "that is not"
          aTitle2 = " ONLY the"
          aAdditionalDescription = "no"
        end
        
        title "Server SHOULD #{aServerStatus} client request with#{aTitle2} following match input element(s) #{aTitle} in conformance with profile IDI Patient #{profile_level_display}: #{test_description}"
        description "Verify that the Patient $match with following input element(s) returns #{aAdditionalDescription} response for profile IDI Patient #{profile_level_display}: #{test_description}"

        run do
          omit_if strict == 'false' or strict === false

          aDOB = bDOB ? '1991-12-31' : nil
          aPhone = bTelecom ? '555-555-5555' : nil
          aStreetAddress = bAddress ? '135 Dolly Madison Pkwy' : nil
          aCity = bCity ? 'McLean' : nil
          aMedicalRecordNumber = bIdentifier ? 'MS12121212' : nil
          aLastName = bLastName ? 'Doe' : nil
          aFirstName = bFirstName ? 'Jane' : nil
          aPassportNumber = bPPN ? 'US53535353' : nil
          aDriversLicenseNumber = bDL ? '999199912' : nil
          aStateID = bSTID ? 'VA55555534' : nil
          aEmail = bEmail ? 'jane_doe@email.com' : nil
      
          baseMatchRequest = MatchRequest.new(aFullName, aDOB, aSex, aPhone, aEmail, aStreetAddress, aCity, aState, aPostalCode, aPassportNumber,
            aDriversLicenseNumber, aStateID, aMasterPatientIndex, aMedicalRecordNumber, aInsuranceMemberNumber, aInsuranceSubscriberNumber, aSocialSecurity, 
            profile_level, aCertainMatchesOnly, aCount, aLastName, aFirstName, aMiddleName)
  
          json_request = baseMatchRequest.build_request_fhir

          profile_display = baseMatchRequest.profile
          
          fhir_parameter = FHIR.from_contents(json_request)

          fhir_operation('Patient/$match', body: fhir_parameter)

          if positive_test
            assert_response_status(200)

            assert_resource_type(:bundle)
          else
            response_status = request.status

            assert(response_status != 200, "FHIR endpoint does not reject a nonconformant client request for profile IDI Patient" + profile_level_display + " with only the following match input element(s): " + test_description)
          end
        end
      end
    end

    test do
      id :patient_match_advanced
      title 'Server SHALL return a bundle resource for advanced $match operation'
      description "Verify that the Patient $match resource returned from the server is a valid FHIR resource."

      makes_request :match_operation_advanced

      run do
        json_request = load_resource('test_queries/patient_match_search_parameter.json')
        fhir_parameter = FHIR.from_contents(json_request)

        fhir_operation('Patient/$match', body: fhir_parameter, name: :match_operation_advanced)

        assert_response_status(200)

        assert_resource_type(:bundle)

        #assert_valid_bundle_entries(resource_types: 'Patient')
      end
    end

    test do
      id :patient_match_resource_in_bundle
      title 'Bundle response for patient $match SHALL contain patient resources'
      description "Verify that Patient $match returns bundle of patient resources"

      uses_request :match_operation_advanced
      
      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

        assert resource.entry.length.positive?, 'Bundle has no entries'

        entry = resource.entry.first

        assert entry.resource.is_a?(FHIR::Patient), 'The first entry in the Bundle is not a Patient'
      end
    end

    test do
      id :search_identity_to_identity
      title 'Server matching and searching SHOULD be Identity-to-Identity, not Record-to-Record'
      description %Q(
        This test will ensure the server matches on Identity-to-Identity and not Record-to-Record.
        Patient records with link of type 'replaced-by' is excluded from the search and match.
      )
      uses_request :match_operation_advanced
      run do
        omit_if strict == 'false' or strict === false

        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

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
      id :every_valid_record
      title 'Server SHOULD return every candidate identity, subject to volume limits'
      description %Q(
        Match output SHOULD contain every record of every candidate identity, subject to volume limits
      )

      # Use saved request/response from fhir_operation call in previous test
      uses_request :match_operation_advanced

      run do
        omit_if strict == 'false' or strict === false
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

        response_json = resource.to_json # resource is body from response as FHIR::Model

        records_returned = resource.total

        #There should be 2 records that are returned
        assert(records_returned >= 2, "Patient $match returned only #{records_returned} records while there are at least 2 patient records")
      end

    end

    test do
      id :patient_link_valid
      title "Server SHOULD indicate linkage between records by the Patient.link field"
      description %Q(
        This test ensures linked patient records are listed in the Patient.link field.
      )

      # Use saved request/response from fhir_operation call in previous test
      uses_request :match_operation_advanced

      run do
        omit_if strict == 'false' or strict === false
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

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
      id :return_patients_score_range
      title "Patient Match SHALL return a score between 0 and 1 for each matched patient resource"
      description %Q(
        This test validates the bundle returned contains patient records with match score of 0.5 or above
      )

      output :matches_out_of_range
      uses_request :match_operation_advanced
      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'
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
      id :return_matched_patients_score_below_point_five
      title "Patient Match SHOULD only return matched patient resource with a score above 0.5"
      description %Q(
        This test validates the bundle returned contains patient records with match score of 0.5 or above
      )

      output :matches_below_point_five
      uses_request :match_operation_advanced
      run do        
        omit_if strict == 'false' or strict === false
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'
        
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
      id :return_computed_score
      title "Patient Match SHOULD designate a grading of match quality using table in section 4.7 Scoring Matches & Responder's System Match Output Quality Score of the implementation guide"
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

      #Declare output variables for parameters passed as json
      output :last_name, :first_name, :middle_name, :full_name, :date_of_birth, :sex, :phone_number, :email, :street_address, :city, :state, :postal_code
      output :passport_number, :state_id, :drivers_license_number, :insurance_member_number, :insurance_subscriber_number, :medical_record_number,
        :master_patient_index, :social_security
      output :given_names, :identifiers, :contact_points, :address
      output :profile_level, :certain_matches_only, :param_count

      #Hold unmatched score records
      unmatchedRecords = []
      unmatched_records_str = ""

      uses_request :match_operation_advanced

      run do
        omit_if strict == 'false' or strict === false
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

        request_json = request.request_body

        matchRequest = MatchRequestJSON.new(request_json)

        output last_name: matchRequest.last_name, first_name: matchRequest.first_name, middle_name: matchRequest.middle_name, full_name: matchRequest.full_name,
          date_of_birth: matchRequest.date_of_birth, sex: matchRequest.sex, phone_number: matchRequest.phone_number, email: matchRequest.email,
          street_address: matchRequest.street_address, city: matchRequest.city, state: matchRequest.state, postal_code: matchRequest.postal_code
        output passport_number: matchRequest.passport_number, state_id: matchRequest.state_id, drivers_license_number: matchRequest.drivers_license_number,
          insurance_member_number: matchRequest.insurance_member_number, insurance_subscriber_number: matchRequest.insurance_subscriber_number,
          medical_record_number: matchRequest.medical_record_number, master_patient_index: matchRequest.master_patient_index,
          social_security: matchRequest.social_security
        output given_names: matchRequest.given_names, identifiers: matchRequest.identifiers, contact_points: matchRequest.contact_points,
          address: matchRequest.address
        output profile_level: matchRequest.profile_level, certain_matches_only: matchRequest.certain_matches_only, param_count: matchRequest.param_count

        response_json = JSON.parse(resource.to_json)

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
      id :sorting_response_by_score
      title "Patient records SHOULD be ordered from most likely match to least likely in the bundle retuned from an 'MPI' query"
      description %Q(
        This test validates the bundle returned is sorted by the score from most likely to least likely
      )

      uses_request :match_operation_advanced

      run do
        omit_if strict == 'false' or strict === false
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from match operation'

        response_json = JSON.parse(resource.to_json)

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
