########################################################################
# AwsSnsSubscription is the +sns_topic_subscription+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSnsTopicSubscription < GeoEngineer::Resource
  validate -> { validate_required_attributes([:protocol, :topic_arn, :endpoint]) }

  after :initialize, -> {
    _terraform_id -> { remote_resource&._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { "#{topic_arn}::#{protocol}::#{endpoint}" }
  }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'topic_arn' => topic_arn,
      'endpoint' => endpoint,
      'protocol' => protocol,
      'confirmation_timeout_in_minutes' => "1",
      'endpoint_auto_confirms' => "false",
      'raw_message_delivery' => "false"
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _get_all_subscriptions(provider).map do |subscription|
      {
        _terraform_id: subscription[:subscription_arn],
        _geo_id: "#{subscription[:topic_arn]}::" \
                 "#{subscription[:protocol]}::" \
                 "#{subscription[:endpoint]}"
      }
    end
  end

  def self._get_all_subscriptions(provider)
    subs_page = AwsClients.sns(provider).list_subscriptions
    subs = subs_page.subscriptions.map(&:to_h)
    while subs_page.next_token
      subs_page = AwsClients.sns(provider).list_subscriptions({ next_token: subs_page.next_token })
      subs.concat subs_page.subscriptions.map(&:to_h)
    end
    subs
  end
end
