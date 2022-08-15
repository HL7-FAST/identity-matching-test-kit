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

    test do
      title 'Server can create patients'
      id :create
      description "Expects route POST <base>/Patient"

      run do
        patient_json = load_resource('technical_create_patient.json')
        patient_fhir = FHIR.from_contents(patient_json)

        begin
            @new_patient_id = client.create(patient_fhir).id
        rescue Exception => e
            fail "Error #{e.class}"
        else
            pass
        end
      end
    end

    test do
      title 'Server can index patients'
      id :index
      description "Expects route GET <base>/Patient"

      run do
        begin
            patients = fhir_read 'Patient'
            patients_fhir = FHIR.from_contents(patients)

            # check response fhir syntax
            @errors = patients_fhir.validate
            fail(errors.to_s) unless @errors.empty?

            # check response is FHIR bundle with atleast 1 Patient
            fail("Expected FHIR Bundle in response") if patients.resourceType != 'Bundle'
            fail("Expected patient entries in bundle") if patients.total < 1

            # check bundle entries for created patient by id
            found = false
            patients.entry.each do |ent|
                id = ent.to_hash.dig('resource', 'id')
                type = ent.to_hash.dig('resource', 'resourceType')
                found ||= ((id == @new_patient_id) && (type == 'Patient'))
            end
            fail("Could not find newly created patient") if !found
        rescue Exception => e
            fail "Error: ..."
        else
            pass
        end
      end
    end

  end
end

