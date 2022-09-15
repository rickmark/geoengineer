########################################################################
class GeoEngineer::Resources::AzureTrafficManagerEndpoint < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }
end
