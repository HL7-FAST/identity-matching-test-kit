

module IdentityMatching
  class IdentityAssurance < Inferno::TestGroup

    title 'Identity Assurance Tests'
    description 'Digital identity assurance for the modern age and complex healthcare market.'
    id :identity_assurance

    test do
      id :nist_800_63
      title 'Conforms to NIST 800-63'
      description <<~DESC
        The National Institute of Science and Technology has published very thorough guidelines
        on identity matching for the complexities of the modern age. This implementation guide
        simply applies their work in the healthcare context. See: https://pages.nist.gov/800-63-3/
      DESC

      run do
        info "This test is an automatic pass, please read ABOUT." # about tab renders descc
        pass
      end
    end

    test do
      id :required_inputs
      title "Certain inputs SHALL be required to verify an individual's identity."
      description <<~DESC
        Required inputs fields are full legal name, home address, date of birth, email address,
        and mobile number.
      DESC

      run do
        # TODO
        # should construct match requests with only partial information and test if server
        # rejects them
        raise StandardError, "Not Implemented"
      end
    end

    test do
      id :verify_email
      title "Server SHOULD verify email at every level of assurance"

      run do
        omit_if !strict

        # TODO
        # this isn't testable without running your own email server,
        # maybe just leave a description and automatically pass
        raise StandardError, "Not Implemented"
      end
    end

    test do
      id :verify_photo
      title "Service provider SHALL verify photo"

      run do
        # TODO
        @passed_verify_photo = true
        # send server match request with photo data and check that it doesn't crash
        # leave message saying photo verification must be done by the service provider (human)
        raise StandardError, "Not Implemented"
      end
    end

    test do
      id :no_knowledge_based_verification
      title "Service provider SHALL NOT use knowledge based verification, unless photo is provided, then MAY use knowledge-based photo verification."
      description <<~DESC
        The service provider cannot use knowledge based verification (KBV) for identity assurance.
        This is usually done by human actors, so from a developer's perspective the software should
        not allow any direct human-based tuning of the identity assurance level or score. HOWEVER if
        a photo is provided, then a human MAY provide input on photo verification compared to their
        knowledge of the individual. The IG is undetermined about AI based photo verification.
      DESC

      run do
        if strict
          info "This test is an automatic pass, please read ABOUT."
          pass
        else
          fail_if !@passed_verify_photo
          info "You MAY do knowledge based verification of photo if one is provided."
          info "Please read ABOUT."
          pass
        end
      end
    end

  end
end

