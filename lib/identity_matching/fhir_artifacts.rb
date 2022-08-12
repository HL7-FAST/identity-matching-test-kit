

module IdentityMatching
  class FHIRArtifacts < Inferno::TestGroup


    # test group metadata
    title 'FHIR Artifacts Tests'
    description <<~DESC
		The patient identity information sent to a conformant server is a Patient FHIR artifact that
		must adhere to one of the following profiles: IDI Patient, IDI Patient L0, or IDI Patient L1.
		The L0 and L1 profiles assert a weighted input validation score of at least 10 and 20
		respectively. All patient profiles must assert their conformance in a meta.profile slice.
		The Patient profile must also be wrapped in a Parameters FHIR artifact, that can additionally
		take a onlyCertainMatches parameter and limit parameter.
	DESC
    id :fhir_artifacts


	# input fields for all tests in group
	input :fhir_parameters,
	  description: "FHIR Parameters resource in JSON for $match"

	# helper functions
	def patient( params )
		params.parameter.each do |param|
			if param.respond_to?( :resource ) && param.resource.resourceType == 'Patient'
				return param.resource
			end
		end
		false
	end


	# actual tests
	test do
	  id :parameters
	  title 'Top-level FHIR Artifact is Parameters ResourceType'

	  run do
		begin
			JSON.parse( fhir_parameters )
		rescue Exception => e
			assert false, "Invalid JSON #{e}"
		end

		params = FHIR.from_contents( fhir_parameters )

		assert params.valid?, "Invalid FHIR format, please go to /validator and double check"
		assert params.resourceType == 'Parameters', 'FHIR Resource is not Parameters'
	  end
	end

	test do
	  id :patient_resource
	  title 'Parameters includes Patient ResourceType'

	  run do
		params = FHIR.from_contents( fhir_parameters )
		assert patient( params ), "Parameters does not include Patient resource"
	  end
	end

    test do
      id :meta_profile
      title 'Patient asserts IDI Patient in meta.profile'

      run do
		params = FHIR.from_contents( fhir_parameters )
		idi_patient = patient( params )
		assert idi_patient, "No Patient"

		profile = idi_patient.to_hash.dig('meta', 'profile', 0)
		assert profile, "Patient resource does not have meta.profile array with entries"

		assert profile.start_with?("http://hl7.org/fhir/us/identity-matching/StructureDefinition/IDI-Patient"), "meta.profile must be a URI of IDI Patient struture definition"

		assert !!/Patient(-L[01])?$/.match?(profile), "meta.profile must be a URI of IDI Patient struture definition"
      end
    end

	test do
	  id :valid_input_weighted
	  title 'Patient resource fields conform to weighted validation asserted by IDI profile'

	  run do
		# TODO
		# could copy function from client or other branch...

		raise StandardError, "Not Implemented"
	  end
	end

  end
end

