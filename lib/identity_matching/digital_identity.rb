

module IdentityMatching
  class DigitalIdentity < Inferno::TestGroup

    title 'Digital Identity Tests'
    description 'Defining novel Digital Identifiers and Enterprise Identifiers for higher fidelity patient matching.'
    id :digital_identity

    test do
      id :unique_digital_identity
      title 'Digital Identity SHALL always be unique in context of digital service'
      description <<~DESC
        A digital service provider can construct their own digital identity of patients (or any other healthcare actor) to manage
        their own transactions with the patient. In this case the digital identity construct of the service provider must be unique
        in that context or service. For example a SQL database of users may use an autoserial integer primary key as their digital
        identifier, and each row in the table will be a unique digital identity. The primary key does not have to be globally unique
        (such as a UUID). This must be enforced on the system level rather than server level.
      DESC

      run do
        pass
        info "This test is an automatic pass, see ABOUT."
      end
    end

    test do
      id :not_real_life
      title "Digital Identity SHALL NOT require subject's real life identity to be evident"
      description <<~DESC
        When the service provider assigns a digital identifier to a user, it cannot require the user to prove their unique real-life
        identity, nor deny new users from onboarding the digital identifier system due to a perceived real-identity conflict. In
        practice this may allow many digital identifiers to map to one user and interoperability systems will be well designed to
        handle that. This must be enforced on a system level rather than server level.
      DESC

      run do
        pass
        info "This test is an automatic pass, see ABOUT."
      end
    end


    test do
      id :identifier_validation
      title 'Identifier SHALL be capable of a validation process'
      description <<~DESC
        Identifier capable of validation by one of following methods:
            1. User authenticates themselves with credentials that originate from another trusted identity provider
                a. The identity provider must achieve Identity Assurance Level 2 (IAL2) for the verification process to assert IAL1
            2. Confirm identifier and verify demographics - first, last, date of birth, home address including zip or city and state
            3. Authorize sharing of demographics with relying party and verify:
                a. Identitifer matches medical record number
                b. Profile photo is visual match
      DESC

      run do
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end

    test do
      id :identity_proofing
      title "Service SHALL perform identity proofing process for individual represented by identifier and include declaration of identity assertion"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end

    test do
      id :differentiate_verified_unverified_attributes
      title "Identity proofing process SHOULD differentiate between verified and unverified identity attributes"
      description ''

      run do
        warn "TODO"
        if strict() == "false" or strict() === false
          omit
        else
          pass
          info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
        end
      end
    end


    test do
      id :unique_identifier_per_time
      title "Identifier SHALL be unique for all time in assigner's system"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :unique_identifier_per_person
      title "Identifier SHALL correspond to a unique person on identity provider's system"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :cannot_reassign_identifier
      title "Identity provider system SHALL NOT reassign identifier to another individual except in the case of name change"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :assert_identity_attributes
      title "Identity provider onboarding SHALL require individual to assert ownership of identity attributes"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :use_legal_name
      title "Identity provider onboarding SHALL use full legal names"
      description ''

      run do
        warn "TODO"
        # info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :discourage_work_numbers
      title "Identity provider onboarding SHOULD discourage use of work addresses or phone numbers to represent individual"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end

    test do
      id :exclusive_control
      title "Phone numbers and email addresses SHALL be under the exclusive control of individual is used to secure identifier or credentials"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end

    test do
      id :fhir_ready_identifiers
      title "Identifiers SHOULD be FHIR-ready and can be associated with an OpenID credential capable of OAuth 2.0 authentication via UDAP Tiered OAuth"
      description <<~DESC
        Other FHIR implementation guides may also leverage the digital identifier specified in this implementation guide, so digital identifiers should be
        designed with other possible interoperability use cases in mind. An immediate alternative implementation guide of concern is UDAP Security. A UUID
        string with UTF-8 encoding will suffice. This must be enforced on a system level rather than server level.
      DESC

      run do
        if strict() == 'false' or strict() === false
          omit
        else
          pass
          info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
        end
      end
    end

    test do
      id :associated
      title "Identifier SHALL be associated with Patient.identifier resource element"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end

    test do
      id :open_id
      title "Identifiers SHOULD appear in OpenID identity claims distinct from subject identifier"
      description <<~DESC
        Example OpenID identity claim utilizing a digital identifier:
            {
               ...
               "iss":"https://generalhospital.example.com/as",
               "sub":"328473298643",                                 # distinct JWT subject id
               "identifier":"123e4567-e89b-12d3-a456-426614174000a", # the digital identifier
               "amr":"http://udap.org/code/auth/aal2",
               "acr":"http://udap.org/code/id/ial2",
               "name": "Jane Doe",
               "given_name": "Jane",
               "family_name": "Doe",
               "birthdate": "1979-01-01",
               "address": {
                 "street_address": "1234 Hollywood Blvd.",
                 "locality": "Los Angeles",
                 "region": "CA",
                 "postal_code": "90210",
                 "country": "US"},
                "email": "janedoe@example.com",
               "picture":"https://generalhospital.example.com/fhir/Patient?identifier=https://generalhospital.example.com/issuer1|123e4567-e89b-12d3-a456-426614174000a"
            }
      DESC

      run do
        if strict() == "false" or strict() === false
          omit
        else
          # TODO: consider querying OPENID metadata, and if claim endpoint found test the claim, else skip test
          info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
          pass
        end
      end
    end


    test do
      id :protected
      title "Identifier SHALL be protected like Social Security Numbers"
      description <<~DESC
        Implementers should follow best privacy and security practices for digital identifiers, which may play a
        significant role in healthcare. Treat them akin to Social Security Numbers.
      DESC

      run do
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :only_for_matching
      title "Identifier SHALL NOT be shared other than for patient matching purposes in a healthcare setting"
      description <<~DESC
        Identifier should follow best privacy practices and only use them when necessary.
      DESC

      run do
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :not_open_id_connect_identifier
      title "Identifier SHALL NOT be the OpenID Connect Identifier"
      description <<~DESC
        In line with best privacy practices, digital identifiers are distinct from OpenID Connect Identifier.
      DESC

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :not_derivable
      title "Identifier SHALL NOT be programmatically derivable or deduced from OpenID Connect Identifier"
      description <<~DESC
        In line with best security practices, digital identifiers cannot be derivable from other identifiers.
      DESC

      run do
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :not_sharable_to_untrusted
      title "Identity provider system SHALL NOT allow individual to authorize sharing of identifier with an endpoint that is not a trusted healthcare organization"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :authentication_assurance
      title "If Identifier is IAL1 or higher, then identity provider system SHALL establish proof of control mechanism conforming to NIST AAL2 or higher authentication level"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :alignment_nist_800_63
      title "Identifier SHALL be in alignment with NIST 800-63-3 unless specified otherwise"
      description <<~DESC
        The National Institute of Science and Technology has published very thorough guidelines
        on identity matching. Digital identifiers shall be compliant with their guidelines, and
        they may offer better clarity on implementing a successful real-world identifier.
        See: https://pages.nist.gov/800-63-3/
      DESC

      run do
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :cannot_reassign_cross_organizational_identifiers
      title "Cross organiztional enterprise identifiers SHALL NOT be reassigned to different people at any point in time"
      description ''

      run do
        warn "TODO"
        pass
        info "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end

    test do
      id :avoid_l_o
      title "Enterprise Identifiers SHOULD avoid the letters I and O as they are difficult to differentiate from 1 and 0."
      description <<~DESC
        For each Patient.identifier.type == "PRN" in GET /Patient assert that Patient.identifier.value does not have I or O.
        Skips test if no Patient.identifier.type == "PRN" found.
      DESC

      run do
        if strict() == 'false' or strict() === false
          omit
        else
          warn "TODO"
          pass
        end
      end
    end

  end
end

