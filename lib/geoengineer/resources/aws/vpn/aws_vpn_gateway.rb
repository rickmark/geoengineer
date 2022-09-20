########################################################################
# AwsVpnGateway is the +aws_vpn_gateway+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpn_gateway.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpnGateway < GeoEngineer::Resource
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { remote_resource&._terraform_id } }
  after :initialize, -> { _geo_id -> { tags&.dig(:Name) } }

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider).describe_vpn_gateways['vpn_gateways'].map(&:to_h).map do |gateway|
      gateway.merge(
        {
          _terraform_id: gateway[:vpn_gateway_id],
          _geo_id: gateway[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
