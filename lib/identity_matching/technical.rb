require_relative 'helper'

module IdentityMatching
  class Technical < Inferno::TestGroup

    include IdentityMatching::Helper # gives access to load_resource()

    title 'Technical Requirements'
    description <<~DESC
        For this test kit to work, the target server must be capable of Patient create and Patient get all,
        which are expected to be implemented at endpoints `POST <base>/Patient`, `GET <base>/Patient`
        respectively. The following tests confirm this functionality.
    DESC
    id :technical

    http_client do
        url :url                    # from test suite input
        bearer_token :access_token
        headers 'application' => 'Content-Type/application+fhir'
    end

    test do
      title 'Server can create patients'
      id :create
      description "Expects route POST <base>/Patient"

      run do
        patient_json = load_resource('technical_create_patient.json')
        patient_fhir = FHIR.from_contents(patient_json)

        response = post('/Patient', body: patient_fhir.to_json, headers: {'Content-Type' => 'application/fhir+json'})
        assert (response.status > 199 && response.status < 300) or (response.status == 303)
        pass
      end
    end

    test do
      title 'Server can index patients'
      id :index
      description "Expects route GET <base>/Patient"

      run do
        response = get('Patient', headrs: {'Content-Type' => 'application/fhir+json'})
        patients_fhir = FHIR.from_contents(response.response_body)
        assert patients_fhir, "Could not parse FHIR response"
        assert response.status == 200, "Expected HTTP 200 OK"

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
      description "This test shall execute ALL test cases if in strict mode, else it will omit SHOULD and MAY test cases."

      run do
        omit_if strict?
        pass
      end
    end

  end
end

