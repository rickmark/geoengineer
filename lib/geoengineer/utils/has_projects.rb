# typed: true
# frozen_string_literal: true
########################################################################
# HasProjects provides methods for a class to contain and query a set of projects
########################################################################
module HasProjects
  extend T::Sig

  sig { returns(T::Hash[String, GeoEngineer::Project]) }
  def projects
    @_projects ||= {}
  end

  sig { params(org: String, name: String, block: T.proc.void).returns(GeoEngineer::Project) }
  # Factory for creating projects
  def create_project(org, name, &block)
    # do not add the project a second time
    repository = "#{org}/#{name}"
    return projects.fetch repository if projects.key?(repository)

    proj = GeoEngineer::Project.new(org, name, self, &block)
    projects[repository] = proj
    proj
  end

  def all_project_resources
    projects.values.map(&:all_resources).flatten
  end
end
