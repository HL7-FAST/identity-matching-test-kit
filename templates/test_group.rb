

module IdentityMatching
  class MyGroup < Inferno::TestGroup

    title 'MyGroup Tests'
    description '...'
    id :my_group

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

