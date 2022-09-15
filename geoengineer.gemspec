require_relative './lib/geoengineer/version'

Gem::Specification.new do |s|
  s.name        = 'geoengineer'
  s.version     = GeoEngineer::VERSION
  s.summary     = "GeoEngineer can codeify, plan and execute changes to cloud resources."
  s.description = <<-EOF
    GeoEngineer provides a Ruby DSL and command line tool (geo)
    to codeify then plan and execute changes to cloud resources using Hashicorp Terraform.
  EOF
  s.homepage    = "https://coinbase.github.io/geoengineer"
  s.authors     = ['coinbase', 'rickmark']
  s.email       = ['graham.jenson@coinbase.com']
  s.license     = 'Apache-2.0'

  s.files       = Dir.glob('lib/**/*.rb')
  s.files       << "README.md"
  s.files       << "LICENSE"

  s.test_files = Dir.glob('spec/**/*.rb')
  s.executables << 'geo'

  s.required_ruby_version = '>= 3.1'
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "yard"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency 'sorbet'

  s.add_dependency 'netaddr'
  s.add_dependency 'aws-sdk'
  s.add_dependency 'commander'
  s.add_dependency 'colorize'
  s.add_dependency 'parallel'
  s.add_dependency 'octokit'
  s.add_dependency 'azure_sdk'
  s.add_dependency 'sorbet-runtime'
  s.add_dependency 'faraday'
  s.add_dependency 'json-schema'
  s.add_dependency 'tty-pager'
  s.add_dependency 'pg'
end
