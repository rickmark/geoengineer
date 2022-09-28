# typed: true
# frozen_string_literal: true
########################################################################
# Outputs are mapped 1:1 to terraform outputs
#
# {https://www.terraform.io/docs/providers/aws/ Terraform Docs}
########################################################################
class GeoEngineer::Provider
  extend T::Sig
  attr_reader :id

  include HasAttributes
  include HasSubResources

  def initialize(id, &)
    @id = id
    instance_exec(self, &) if block_given?
  end

  sig { returns(String) }
  def terraform_id
    if self.alias
      "#{id}.#{self.alias}"
    else
      id
    end
  end

  ## Terraform methods
  sig { returns(String) }
  def to_terraform
    sb = ["provider #{@id.inspect} { "]

    sb.concat terraform_attributes.map { |k, v|
      "  #{k.to_s.inspect} = #{v.inspect}"
    }

    sb.concat subresources.map(&:to_terraform)
    sb << " }"
    sb.join("\n")
  end

  def to_terraform_json
    json = terraform_attributes
    subresources.map(&:to_terraform_json).each do |k, v|
      json[k] ||= []
      json[k] << v
    end
    { id.to_s => json }
  end
end
