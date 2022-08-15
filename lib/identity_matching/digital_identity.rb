

module IdentityMatching
  class DigitalIdentity < Inferno::TestGroup

    title 'Digital Identity Tests'
    description 'Defining novel Digital Identifiers and Enterprise Identifiers for higher fidelity patient matching.'
    id :digital_identity

    test do
      id :exist
      title 'I exist'
      description 'Fill with your test here'

      run do
		assert true, "error... how?!"
      end
    end

    test do
      id :unique_digital_identity
      title 'Digital Identity SHALL always be unique in context of digital service'
      description ''

      run do
		# TODO
		raise StandardError, "Not Implemented"
      end
    end

    test do
      id :not_real_life
      title "Digital Identity SHALL NOT require subject's real life identity to be evident"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :identifier_validation
      title 'Identifier SHALL be capable of a validation process'
      description <<~DESC
		Identifier capable of validation by one of following methods:
			1. AAL2 or greater and originate from trusted provider
			2. Confirm identifier and verify demographics - first, last, date of birth, home address including zip or city and state
			3. Authorize sharing of demographics with relying party and verify:
			    a. Identitifer matches medical record number
				b. Profile photo is visual match
	  DESC

      run do
		# TODO
		skip
      end
    end

    test do
      id :identity_proofing
      title "Service SHALL perform identity proofing process for individual represented by identifier and include declaration of identity assertion"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :differentiate_verified_unverified_attributes
      title "Identity proofing process SHOULD differentiate between verified and unverified identity attributes"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :unique_identifier_per_time
      title "Identifier SHALL be unique for all time in assigner's system"
      description ''

      run do
		# TODO
		skip
      end
    end

    test do
      id :unique_identifier_per_person
      title "Identifier SHALL correspond to a unique person on identity provider's system"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :cannot_reassign_identifier
      title "Identity provider system SHALL NOT reassign identifier to another individual except in the case of name change"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :assert_identity_attributes
      title "Identity provider onboarding SHALL require individual to assert ownership of identity attributes"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :use_legal_name
      title "Identity provider onboarding SHALL use full legal names"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :discourage_work_numbers
      title "Identity provider onboarding SHOULD discourage use of work addresses or phone numbers to represent individual"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :exclusive_control
      title "Phone numbers and email addresses SHALL be under the exclusive control of individual is used to secure identifier or credentials"
      description ''

      run do
		# TODO
		skip
      end
    end

	test do
	  id :fhir_ready_identifiers
	  title "Identifiers SHOULD be FHIR-ready and can be associated with an OpenID credential capable of OAuth 2.0 authentication via UDAP Tiered OAuth"
	  description ''

	  run do
		# TODO
		skip
	  end
	end


    test do
      id :associated
      title "Identifier SHALL be associated with Patient.identifier resource element"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :open_id
      title "Identifiers SHOULD appear in OpenID identity claims distinct from subject identifier"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :protected
      title "identifier SHALL be protected like social security numbers"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :only_for_matching
      title "Identifier SHALL NOT be used outside of patient matching purposes in a healthcare setting"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :not_open_id_connect_identifier
      title "Identifier SHALL NOT be the OpenID Connect Identifier"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :not_derivable
      title "Identifier SHALL NOT be programmatically derivable or deduced from OpenID Connect Identifier"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :not_sharable_to_untrusted
      title "Identity provider system SHALL NOT allow individual to authorize sharing of identifier with an endpoint that is not a trusted healthcare organization"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :authentication_assurance
      title "If Identifier is IAL1 or higher, then identity provider system SHALL establish proof of control mechanism conforming to NIST AAL2 or higher authentication level"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :alignment_nist_800_63
      title "Identifier SHALL be in alignment with NIST 800-63-3 unless specified otherwise"
      description ''

      run do
		# TODO
		skip
      end
    end


    test do
      id :cannot_reassign_cross_organizational_identifiers
      title "Cross organiztional enterprise identifiers SHALL NOT be reassigned to different people at any point in time"
      description ''

      run do
		# TODO
		skip
      end
    end


  end
end

