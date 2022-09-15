########################################################################
# HasProjects provides methods for a class to contain and query a set of projects
########################################################################
module HasProjects
  def projects
    @_projects ||= {}
  end

  # Factory for creating projects
  def create_project(org, name, &)
    # do not add the project a second time
    repository = "#{org}/#{name}"
    return projects[repository] if projects.key?(repository)

    proj = GeoEngineer::Project.new(org, name, self, &)
    projects[repository] = proj
    proj
  end

  def all_project_resources
    projects.values.map(&:all_resources).flatten
  end
end
