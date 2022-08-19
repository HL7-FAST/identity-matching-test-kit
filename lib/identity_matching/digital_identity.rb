

module IdentityMatching
  class DigitalIdentity < Inferno::TestGroup

    title 'Digital Identity Tests'
    description 'Defining novel Digital Identifiers and Enterprise Identifiers for higher fidelity patient matching.'
    id :digital_identity

    http_client do
        url :url                    # from test suite input
        #bearer_token :access_token
        headers 'application' => 'Content-Type/application+fhir'
    end


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
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
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
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :identifier_validation
      title 'Identifier SHALL be capable of a validation process'
      description <<~DESC
        Identifier capable of validation by one of following methods:
            1. User authenticates themselves with credentials that originate from another trusted identity provider.
                1a. The identity provider must achieve Identity Assurance Level 2 (IAL2) for the verification process to assert IAL1.
            2. Confirm identifier and verify demographics - first, last, date of birth, home address including zip or city and state.
            3. Authorize sharing of demographics with relying party and verify:
                3a. Identitifer matches medical record number.
                3b. Profile photo is visual match.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :identity_proofing
      title "Service SHALL perform identity proofing process for individual represented by identifier and include declaration of identity assertion"
      description <<~DESC
        There must be a documented identity proofing processes that will prevent faudulent claim to a false identity. This requires the Identity Provider to follow a process that is IAL1.5 or higher. This must be enforced at a system level rather than server level.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :differentiate_verified_unverified_attributes
      title "Identity proofing process SHOULD differentiate between verified and unverified identity attributes"
      description <<~DESC
        Identity Providers should record excatly what identity attributes were validated and at what time. Future releases of the implementation guide or IAL1.5 revisions may require these attributes to be flagged as verified with a timestamp.
      DESC

      run do
        if strict() == "false" or strict() === false
          omit
        else
          pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
        end
      end
    end


    test do
      id :unique_identifier_per_time
      title "Identifier SHALL be unique for all time in assigner's system"
      description <<~DESC
        This is infeasable to test in a basic test kit, but in practice the server must ensure there are no race conditions in assigning identifiers. See UUIDs or Twitter Snowflake IDs for good examples.
      DESC

      # TODO: right choice?
      # alternative test: create a gazillion patients and check if all their id's are unique, aka try to cause race conditions by attacking the server

      run do
        pass "This test is an automatic pass, but see ABOUT."
      end
    end


    test do
      id :unique_identifier_per_person
      title "Identifier SHALL correspond to a unique person on identity provider's system"
      description <<~DESC
        There must be a 1:1 mapping from Digital Identifier to person in Identity Provider's system. This must be enforced at a system level rather than server level.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :cannot_reassign_identifier
      title "Identity provider system SHALL NOT reassign identifier to another individual except in the case of name change"
      description <<~DESC
        The exact details of name changeing are upto the implementer until further specifications are provided in this or another implementation guide.
	  DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :assert_identity_attributes
      title "Identity provider onboarding SHALL require individual to assert ownership of identity attributes"
      description <<~DESC
        This must be enforced at a system level rather than server level.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :use_legal_name
      title "Identity provider onboarding SHALL use full legal names"
      description <<~DESC
        Test for at least one Patient.name[i].use == 'official' or assumed official if unspecified.
      DESC

      run do
        response = get('Patient')
        assert response.status == 200, "Expected HTTP 200 Response"
        begin
          JSON.parse(response.response_body)
        rescue
          fail("Expected JSON Response")
        end

        begin
          bundle = FHIR.from_contents(response.response_body)
        rescue
          fail("Expected FHIR Response")
        end

        fail("Invalid FHIR Syntax") if !bundle.valid?

        bundle.entry.select{|e| e.respond_to? :resource}.map{|e| e.resource}.each do |resource|
          if resource.resourceType == 'Patient' then
            assert resource.respond_to?(:name) && !resource.name.empty?, "No names found for patient #{resource.id}"
            legal_name = resource.name.index {|human_name| !human_name.respond_to?(:use) || human_name.use.nil? || (human_name.use == 'official') }
            info "Failed because of Patient.name[#{legal_name}] where Patient.id == #{resource.id}" if !legal_name
            assert !!legal_name, "No full legal name found"
          end
        end
      end
    end


    test do
      id :discourage_work_numbers
      title "Identity provider onboarding SHOULD discourage use of work addresses or phone numbers to represent individual"
      description <<~DESC
        Personal addresses and phone numbers should be preferred. This must be enforced on a system level rather than server level.
      DESC

      run do
        if strict() == 'false' or strict() === false
            omit
        else
            pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
        end
      end
    end


    test do
      id :exclusive_control
      title "Phone numbers and email addresses SHALL be under the exclusive control of individual if used to secure identifier or credentials"
      description <<~DESC
        Two factor authentication is a good (albiet not perfect) way to enforce this.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
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
          pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
        end
      end
    end


    test do
      id :associated
      title "Identifier SHALL be associated with Patient.identifier resource element"
      description <<~DESC
          Test creates a patient with a digital identifier field and asks server to $match patient with given identifier.
      DESC

      run do
        warn "TODO"
        skip "Unimplemented" # run match with an identifier
      end
    end

    test do
      id :open_id
      title "Identifiers SHOULD appear in OpenID identity claims distinct from subject identifier"
      description <<~DESC
        A production server with patient matching would greatly benefit from implementing OAuth2 and OpenID Connect. Example OpenID identity claim utilizing a digital identifier:
            {
               "iss":"https://generalhospital.example.com/as",
               "sub":"328473298643",
               "identifier":"123e4567-e89b-12d3-a456-426614174000a",
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
          pass "This test is an automatic pass because OpenID Connect is out of scope for this implementation guide. See ABOUT."
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
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :only_for_matching
      title "Identifier SHALL NOT be shared other than for patient matching purposes in a healthcare setting"
      description <<~DESC
        Identifier should follow best privacy practices and only use them when necessary.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :not_open_id_connect_identifier
      title "Identifier SHALL NOT be the OpenID Connect Identifier"
      description <<~DESC
        In line with best privacy practices, digital identifiers are distinct from OpenID Connect Identifier.
      DESC

      run do
        # TODO: consider could query OPENID metadata and if claim endpoint found test claim
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :not_derivable
      title "Identifier SHALL NOT be programmatically derivable or deduced from OpenID Connect Identifier"
      description <<~DESC
        In line with best security practices, digital identifiers cannot be derivable from other identifiers.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :not_sharable_to_untrusted
      title "Identity provider system SHALL NOT allow individual to authorize sharing of identifier with an endpoint that is not a trusted healthcare organization"
      description <<~DESC
        If the Digital Identifier Service comes with a consumer-facing application, then it cannot allow a user to share their identifier with anyone for any reason.
        The UDAP Security implementation guide details a solution to this problem using trusted certificate chains.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :authentication_assurance
      title "If Identifier is IAL1 or higher, then identity provider system SHALL establish proof of control mechanism conforming to NIST IAL2 or higher authentication level"
      description <<~DESC
          Examples include 2-factor authentication schemes. This must be implemented at a system level rather than server level.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
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
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end


    test do
      id :cannot_reassign_cross_organizational_identifiers
      title "Cross organiztional enterprise identifiers SHALL NOT be reassigned to different people at any point in time"
      description <<~DESC
          This must be implemented at a system level rather than server level.
      DESC

      run do
        pass "This test is an automatic pass, but service provider must conform to specification above. See ABOUT."
      end
    end

    test do
      id :avoid_l_o
      title "Enterprise Identifiers SHOULD avoid the letters I and O as they are difficult to differentiate from 1 and 0."
      description <<~DESC
        For each Patient.identifier.type == "PRN" assert that Patient.identifier.value does not have I or O.
        Skips test if no Patient.identifier.type == "PRN" found.
      DESC

      # TODO: check if PRN is correct type
      # TODO: run test as described above, or omit for being out of scope

      run do
        if strict() == 'false' or strict() === false
          omit
        else
          response = get('Patient')
          assert response.status == 200, "Expected HTTP 200 Response"
          begin
            JSON.parse(response.response_body)
          rescue
            fail("Expected JSON Response")
          end

          begin
            bundle = FHIR.from_contents(response.response_body)
          rescue
            fail("Expected FHIR Response")
          end

          fail("Invalid FHIR Syntax") if !bundle.valid?

          found_type = false
          bundle.entry.select{|e| e.respond_to? :resource}.map{|e| e.resource}.each do |resource|
            if (resource.resourceType == 'Patient') && resource.identifier && !resource.identifier.empty? then
                identifiers = resource.identifier.select {|x| x.type&.coding&.any? {|c| c.system == 'http://terminology.hl7.org/CodeSystem/v2-0203' and c.code == 'PRN'} }
                found_type ||= true if !identifiers.empty?
                identifiers.each_with_index do |x, i|
                    assert !x.include?('I'), "Patient.identifier[#{i}] includes 'I' where Patient.id == #{resource.id}"
                    assert !x.include?('O'), "Patient.identifier[#{i}] includes 'O' where Patient.id == #{resource.id}"
                end
            end
          end
          skip "No Enterprise Identifiers found" if !found_type
        end
      end
    end

  end
end

