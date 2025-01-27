# typed: true

require 'yaml'

###
# GPS Geo Planning System
# This module is designed as a higher abstraction above the "resources" level
# The abstraction is built for engineers to use so is in their vocabulary
# As each engineering team is different GPS is only building blocks
# GPS is not a complete solution
###
class GeoEngineer::GPS
  extend T::Sig

  class GPSProjectNotFound < StandardError; end
  class NodeTypeNotFound < StandardError; end
  class MetaNodeError < StandardError; end
  class LoadError < StandardError; end

  GPS_FILE_EXTENSION = ".gps.yml".freeze

  def self.json_schema
    node_names = {
      type:  "object",
      "additionalProperties" => {
        type:  "object"
      }
    }

    node_types = {
      type:  "object",
      "additionalProperties" => node_names
    }

    configurations = {
      type:  "object",
      "additionalProperties" => node_types
    }

    {
      type:  "object",
      "additionalProperties" => configurations,
      minProperties: 1
    }
  end

  # Load
  sig { params(gps_instance: GeoEngineer::GPS, gps_file: String).void }
  def self.load_gps_file(gps_instance, gps_file)
    raise "The file \"#{gps_file}\" does not exist" unless File.exist?(gps_file)

    # partial file name is the
    partial_file_name = gps_file.gsub(".gps.yml", ".rb")

    if File.exist?(partial_file_name)
      # if the partial file exists we load the file directly
      # This will create the GPS resources
      require "#{Dir.pwd}/#{partial_file_name}"
    else
      # otherwise initialize for the partial directly here
      gps_instance.partial_of(partial_file_name)
    end
  end

  sig { params(gps_file: String).void }
  def load_gps_file(gps_file)
    GeoEngineer::GPS.load_gps_file(self, gps_file)
  end

  # Parse
  sig { params(dir: String, schema: T.nilable(Hash)).returns(Hash) }
  def self.parse_dir(dir, schema = nil)
    # Load, expand then merge all yml files
    Dir["#{dir}**/*#{GPS_FILE_EXTENSION}"].reduce({}) do |new_hash, gps_file|
      begin
        # Merge Keys don't work with YAML.safe_load
        # since we are also loading Ruby safe_load is not needed
        gps_hash = YAML.load(File.read(gps_file))
        # remove all keys starting with `_` to remove partials
        gps_hash = HashUtils.remove_(gps_hash)
        JSON::Validator.validate!(schema, gps_hash) if schema

        # base name is the path + file
        base_name = gps_file.sub(dir, "")[0...-GPS_FILE_EXTENSION.length]

        new_hash.merge({ base_name.to_s => gps_hash })
      rescue StandardError => e
        raise LoadError, "Could not load #{gps_file}: #{e.message}"
      end
    end
  end

  def self.load_projects(dir, constants)
    GeoEngineer::GPS.new(parse_dir(dir, json_schema), constants)
  end

  def self.load_constants(dir)
    GeoEngineer::GPS::Constants.new(parse_dir(dir))
  end

  attr_reader :base_hash, :constants

  sig { params(base_hash: Hash, constants: T.any(GeoEngineer::GPS::Constants, Hash)).void }
  def initialize(base_hash = {}, constants = {})
    # Base Hash is the unedited input, useful for debugging
    @base_hash = base_hash
    @constants = constants
  end

  def nodes
    return @_nodes if @_nodes

    @_nodes = []
    loop_projects_hash(@base_hash) do |node|
      @_nodes << node
    end

    # add pre-context
    nodes_hash = GeoEngineer::GPS::Finder.build_nodes_lookup_hash(@_nodes)
    @_nodes.each { |node| node.set_values(nodes_hash, @constants) }

    @_nodes.each(&:validate) # validate all nodes

    @_nodes = expand_meta_nodes(@_nodes, @_nodes) # this validates as it expands

    nodes_hash = GeoEngineer::GPS::Finder.build_nodes_lookup_hash(@_nodes)
    @_nodes.each { |node| node.set_values(nodes_hash, @constants) }

    @_nodes
  end

  def finder
    @finder ||= GeoEngineer::GPS::Finder.new(nodes, constants)
  end

  def find(query)
    finder.find(query)
  end

  def where(query)
    finder.where(query)
  end

  def dereference(reference)
    finder.dereference(reference)
  end

  def to_h
    @base_hash
  end

  def expanded_hash
    expanded_hash = {}
    nodes.each do |n|
      proj = expanded_hash[n.project] ||= {}
      env = proj[n.environment] ||= {}
      conf = env[n.configuration] ||= {}
      nt = conf[n.node_type] ||= {}
      nt[n.node_name] ||= n.attributes
    end
    HashUtils.json_dup(expanded_hash)
  end

  def loop_projects_hash(projects_hash, &)
    projects_hash.each_pair do |project, environments|
      # If the environments includes _default, pull out its value, and loop over
      # all other known environments and add it back in, if it doesn't already
      # exist. This allows _default to be used as a template for cookie cutter
      # definitions.
      if environments.key?("_default")
        default_env = environments.delete("_default")

        # NOTE: the constants appeared to be the best place to easily get all known environments.
        all_environments = @constants.constants.keys.reject { |env| env.start_with?('_') }
        all_environments.each do |env|
          environments[env] = HashUtils.deep_dup(default_env) unless environments[env]
        end
      end

      environments.each_pair do |environment, configurations|
        configurations.each_pair do |configuration, nodes|
          loop_nodes(project, environment, configuration, nodes, &)
        end
      end
    end
  end

  def loop_nodes(project, environment, configuration, nodes)
    nodes.each_pair do |node_type, node_names|
      node_names.each_pair do |node_name, attributes|
        node_type_class = find_node_class(node_type.to_s)

        yield node_type_class.new(project, environment, configuration, node_name, attributes)
      end
    end
  end

  def expand_meta_node(node, all_nodes)
    expanded_nodes = []
    bn = node.build_nodes
    loop_nodes(node.project, node.environment, node.configuration, bn) do |new_node|
      new_node.set_values(all_nodes, @constants)
      new_node.add_depends_on(node.depends_on) # pass dependencies along
      new_node.validate
      expanded_nodes << new_node
    end

    # recurse through to further expand
    expand_meta_nodes(expanded_nodes, all_nodes)
  end

  def expand_meta_nodes(nodes, all_nodes)
    # dup the list to create new list
    expanded_nodes = nodes.dup
    nodes.each do |node|
      next unless node.meta?

      built_nodes = expand_meta_node(node, all_nodes)
      built_nodes.each do |built_node|
        # Error if the meta-node is overwriting an existing node
        already_built_error = "\"#{node.node_name}\" overwrites node \"#{built_node.node_name}\""
        raise MetaNodeError, already_built_error if expanded_nodes.map(&:node_id).include? built_node.node_id
        expanded_nodes << built_node
      end
    end

    expanded_nodes
  end

  # This method takes the file name of the geoengineer project file
  # it calculates the location of the gps file
  def partial_of(file_name, &)
    # Make relative to pwd
    file_name = file_name.sub("#{Dir.pwd}/", "")

    projects_str, org_name, project_name = file_name.gsub(".rb", "").split("/", 3)

    raise "projects file #{file_name} must be in 'projects' folder is in '#{projects_str}' folder" if projects_str != "projects"

    full_name = "#{org_name}/#{project_name}"

    @created_projects ||= {}
    return if @created_projects[full_name] == true
    @created_projects[full_name] = true

    create_project(org_name, project_name, env, &)
  end

  sig { params(org: String, name: String, environment: GeoEngineer::Environment, with: T.nilable(T.proc.void)).returns(GeoEngineer::Project) }
  def create_project(org, name, environment, &with)
    project_name = "#{org}/#{name}"
    environment_name = environment.name
    project_environments = project_environments(project_name)

    raise GPSProjectNotFound, "project not found \"#{project_name}\"" unless project?(project_name)

    project = environment.project(org, name) do
      self.environment = project_environments
    end

    project = T.must(project)

    project_nodes = where("#{project_name}:#{environment_name}:*:*:*")
    create_all_resource_for_project(project, project_nodes)

    project_configurations(project_name, environment_name).each do |configuration|
      # yield to the given block nodes per-config
      nw = GeoEngineer::GPS::NodesContext.new(project_name, environment_name, configuration, nodes, constants)
      yield(project, configuration, nw) if block_given? && project_nodes.any?
    end

    project
  end

  def create_all_resource_for_project(project, project_nodes)
    project_nodes.each do |n|
      begin
        n.create_resources(project) unless n.meta?
      rescue StandardError => e
        # adding context to error
        raise $ERROR_INFO, [n.node_id, e.message].join(": "), $ERROR_INFO.backtrace
      end
    end
  end

  def project?(project)
    !!@base_hash[project]
  end

  def project_environments(project)
    @base_hash[project].keys || []
  end

  def project_configurations(project, environment)
    @base_hash.dig(project, environment)&.keys || []
  end

  sig { params(type: String).returns(Class) }
  # find node type
  def find_node_class(type)
    clazz_name = type.split('_').collect(&:capitalize).join
    module_clazz = "GeoEngineer::GPS::Nodes::#{clazz_name}"
    return Object.const_get(module_clazz) if Object.const_defined? module_clazz

    raise NodeTypeNotFound, "not found node type '#{type}' for '#{clazz_name}' or '#{module_clazz}'"
  end
end
