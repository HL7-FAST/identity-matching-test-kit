

module IdentityMatching
  class IdentityAssurance < Inferno::TestGroup

    title 'Identity Assurance Tests'
    description '...'
    id :identity_assurance

    test do
      id :exist
      title 'I exist'
      description 'Fill with your test here'

      run do
		assert true, "error... how?!"
      end
    end


  end
end

