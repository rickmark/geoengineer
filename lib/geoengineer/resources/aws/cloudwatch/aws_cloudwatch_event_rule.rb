########################################################################
# AwsCloudwatchEventRule is the +aws_cloudwatch_event_rule+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_rule.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCloudwatchEventRule < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }
  validate -> { validate_schedule_or_event }

  def validate_schedule_or_event
    return if !self[:schedule_expression] && self[:event_pattern]
    return if self[:schedule_expression] && !self[:event_pattern]
    ["#{self.id}: Need either schedule_expression or event_pattern defined"]
  end

  after :initialize, -> { _terraform_id -> { remote_resource&._terraform_id } }
  after :initialize, -> { _geo_id       -> { self[:name] } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .cloudwatchevents(provider)
      .list_rules.rules.map(&:to_h).map do |cloudwatch_event_rule|
      cloudwatch_event_rule.merge(
        {
          _terraform_id: cloudwatch_event_rule[:name],
          _geo_id: cloudwatch_event_rule[:name]
        }
      )
    end
  end
end
