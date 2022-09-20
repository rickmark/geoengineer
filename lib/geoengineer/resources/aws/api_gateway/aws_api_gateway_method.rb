require_relative "./helpers"

########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayMethod < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:rest_api_id, :resource_id, :http_method, :authorization]) }
  validate -> do
    validate_required_attributes([:authorizer_id]) if ['CUSTOM', 'COGNITO_USER_POOLS'].include?(:authorization)
  end

  # Must pass the rest_api as _rest_api resource for additional information
  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _rest_api.api_resources[self._type][self.id] = self }

  after :initialize, -> { self.authorizer_id = _authorizer.to_ref if _authorizer }

  after :initialize, -> { self.resource_id = _resource.to_ref }
  after :initialize, -> { depends_on [_rest_api, _resource].map(&:terraform_name) }

  after :initialize, -> {
                       _geo_id -> {
                                 "#{_rest_api._geo_id}::#{_resource._geo_id}::#{http_method}"
                               } }

  after :initialize, -> { _terraform_id -> { remote_resource&._terraform_id } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] =
      if self.authorizer_id && ['CUSTOM', 'COGNITO_USER_POOLS'].include?(authorization)
        {
          "rest_api_id" => _rest_api._terraform_id,
          "resource_id" => _resource._terraform_id,
          "http_method" => http_method,
          "authorization" => authorization,
          "authorizer_id" => _authorizer.terraform_id
        }
      else
        {
          "rest_api_id" => _rest_api._terraform_id,
          "resource_id" => _resource._terraform_id,
          "http_method" => http_method,
          "authorization" => authorization
        }
      end
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_api_resource_method(provider) do |rr, res, meth|
      api_method = self._fetch_method(provider, rr, res, meth)
      next nil if api_method.nil?

      api_method[:_terraform_id] = "agm-#{rr[:_terraform_id]}-#{res[:_terraform_id]}-#{meth}"
      api_method[:_geo_id] = "#{rr[:_geo_id]}::#{res[:_geo_id]}::#{meth}"
      api_method
    end.flatten.compact
  end
end
