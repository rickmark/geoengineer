########################################################################
# AwsEip is the +aws_eip+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/eip.html Terraform Docs}
########################################################################

# Currently geo can't create EIPs - only codify existing ones
# It does this by requiring the '_public_ip' attribute and hard-coding the '_geo_id' to that
class GeoEngineer::Resources::AwsEip < GeoEngineer::Resource
  validate :validate_instance_or_network_interface

  after :initialize, -> { _terraform_id -> { remote_resource&._terraform_id } }
  after :initialize, -> { _geo_id -> { tags&.dig(:Name) } }

  # Can't associate both an instance and a network interface with an elastic IP
  def validate_instance_or_network_interface
    errors = []

    unless instance.nil? || network_interface.nil?
      errors << "Must associate and Elastic IP with either and EC2 instance or a network interface"
    end

    errors
  end

  def support_tags?
    true
  end

  # Always create within a VPC
  def vpc
    true
  end

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider).describe_addresses['addresses'].map(&:to_h).map do |address|
      address[:_terraform_id] = address[:allocation_id]
      address[:_geo_id] = address[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
      address
    end
  end
end
