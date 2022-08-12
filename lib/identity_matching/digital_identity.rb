

module IdentityMatching
  class DigitalIdentity < Inferno::TestGroup

    title 'Digital Identity Tests'
    description '...'
    id :digital_identity

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

