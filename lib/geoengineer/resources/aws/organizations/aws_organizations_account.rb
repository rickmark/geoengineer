########################################################################
# AwsOrganizationsAccount is the +aws_organizations_account+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/organizations_account.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsOrganizationsAccount < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :email]) }

  after :initialize, -> {
    _terraform_id -> { remote_resource&._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { name }

    # Have terraform ignore changes to role_name because this value is only used
    # on creation and not persisted.
    self.lifecycle {} unless self.lifecycle
    self.lifecycle.ignore_changes ||= []
    self.lifecycle.ignore_changes |= ["role_name", "iam_user_access_to_billing"]
  }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    accounts = []

    response = AwsClients.organizations(provider).list_accounts
    accounts += response.accounts
    while response.next_page?
      response = response.next_page
      accounts += response.accounts
    end

    accounts.map(&:to_h).map do |ac|
      {
        _terraform_id: ac[:id],
        _geo_id: ac[:name],
        name: ac[:name]
      }
    end
  end
end
