Gem::Specification.new do |spec|
  spec.name          = 'identity_matching'
  spec.version       = '0.0.1'
  spec.authors       = ['HL7-FAST']
  spec.email         = ['inferno@groups.mitre.org']
  spec.date          = Time.now.utc.strftime('%Y-%m-%d')
  spec.summary       = 'Identity Matching Test Kit'
  spec.description   = 'Inferno Test Kit for Identity Matching implementation guide by HL7 FHIR At Scale Taskforce.'
  spec.homepage      = 'http://build.fhir.org/ig/HL7/fhir-identity-matching-ig/'
  spec.license       = 'Apache-2.0'
  spec.add_runtime_dependency 'inferno_core', '~> 0.3.0'
  spec.add_development_dependency 'database_cleaner-sequel', '~> 1.8'
  spec.add_development_dependency 'factory_bot', '~> 6.1'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'webmock', '~> 3.11'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/HL7-FAST/identity-matching-test-kit'
  spec.files = [
    Dir['lib/**/*.rb'],
    Dir['lib/**/*.json'],
    Dir['resources/**/*'],
    'LICENSE'
  ].flatten

  spec.require_paths = ['lib']
  spec.add_runtime_dependency "activesupport"
end
