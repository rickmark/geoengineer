require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsEfsMountTarget) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create a list of mount targets returned from the AWS sdk' do
      efs = AwsClients.efs
      stub = efs.stub_data(
        :describe_mount_targets,
        {
          mount_targets: [
            {
              mount_target_id: "fs-01234567"
            },
            {
              mount_target_id: "fs-89012345"
            }
          ]
        }
      )
      efs.stub_responses(:describe_mount_targets, stub)
      remote_resources = GeoEngineer::Resources::AwsEfsMountTarget._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
      expect(remote_resources.first[:mount_target_id]).to eq "fs-01234567"
    end
  end
end
