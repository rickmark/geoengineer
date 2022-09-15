# This ruby file includes the GeoCLI global methods
# It should not be included in the library
require_relative './geo_cli'

def environment(name, remote_state = false, &)
  GeoCLI.instance.create_environment(name, remote_state, &)
end

def env
  GeoCLI.instance.environment
end

def gps
  GeoCLI.instance.gps
end

def project(org, name, &)
  GeoCLI.instance.environment.project(org, name, &)
end
