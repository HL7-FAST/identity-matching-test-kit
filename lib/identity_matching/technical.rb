require 'inferno/dsl/oauth_credentials'
require_relative 'helper'

module IdentityMatching
  class Technical < Inferno::TestGroup

    include IdentityMatching::Helper # gives access to load_resource()

    title 'Technical Requirements'
    description <<~DESC
        For this test kit to work, the target server must be capable of Patient create and Patient get all
        in JSON format, which are expected to be implemented at endpoints `POST <base>/Patient`, `GET <base>/Patient`
        respectively. The following tests confirm this functionality.
    DESC
    id :technical

    http_client do
        url :url                    # from test suite input
        #bearer_token :access_token
        headers 'Accept' => 'application/fhir+json;application/json;text/json'
    end

    test do
      title 'Server can create patients'
      id :create
      description "Expects route POST <base>/Patient"

      run do
        patient_json = load_resource('technical_create_patient.json')
        patient_fhir = FHIR.from_contents(patient_json)

        response = post('Patient', body: patient_fhir.to_json, headers: {'Content-Type' => 'application/fhir+json'})
        assert (response.status > 199 && response.status < 300) or (response.status == 303)
      end
    end

    #Add 5 patients for patient match
    test do
      title 'Server can create patients for $match'
      id :create_for_match_operation
      description "Expects five patients to be created for patient match"

      output :patients_for_patient_match

      run do
        patients = []
        patients << {patient_id: "1244780", path: "test_patients/patient0.json"}
        patients << {patient_id: "151204", path: "test_patients/patient1.json"}
        patients << {patient_id: "1433204", path: "test_patients/patient2.json"}
        patients << {patient_id: "1244794", path: "test_patients/patient3.json"}
        patients << {patient_id: "pat013", path: "test_patients/patient4.json"}
        
        record_creation_status = ''

        patients.each do |patient|
          patientID = patient[:patient_id]
          resourcePath = patient[:path]

          fhir_read(:patient, patientID)
          if request.status = 200
            record_creation_status = record_creation_status + "Patient ID: " + patientID + " already exists; "
          else
            patient_json = load_resource(resourcePath)
            patient_fhir = FHIR.from_contents(patient_json)
  
            response = post('Patient', body: patient_fhir.to_json, headers: {'Content-Type' => 'application/fhir+json'})
            assert (response.status > 199 && response.status < 300) or (response.status == 303)
            record_creation_status = record_creation_status + "Patient ID: " + patientID + " has been created; "
          end
        end
        output patients_for_patient_match: record_creation_status
      end
    end

    test do
      title 'Server can index patients'
      id :index
      description "Expects route GET <base>/Patient"

      run do
        response = get('Patient')
        assert response.status == 200, "Expected HTTP 200 OK"

        begin
          JSON.parse(response.response_body)
        rescue
          fail("Excepted JSON response")
        end

        begin
          patients_fhir = FHIR.from_contents(response.response_body)
        rescue
          fail("Could not parse FHIR response")
        end
        assert patients_fhir, "Could not parse FHIR response"

        # check response fhir syntax
        @errors = patients_fhir.validate
        fail(errors.to_s) unless @errors.empty?

        # check response is FHIR bundle with atleast 1 Patient
        fail("Expected FHIR Bundle in response") if patients_fhir.resourceType != 'Bundle'
        fail("Expected patient entries in bundle") if patients_fhir.total < 1
      end
    end

    # TODO remove - this is for my own sake
    test do
      title 'Test Kit is in Strict mode'
      id :not_strict
      description "This test kit shall execute ALL test cases if in strict mode, else it will omit SHOULD and MAY test cases."

      run do
        omit_if strict == 'false' or strict === false
        pass
      end
    end

  end
end

