require 'contentful/database_importer/version'
require 'contentful/database_importer/config'
require 'contentful/database_importer/resource'
require 'contentful/database_importer/id_generator'
require 'contentful/database_importer/json_generator'
require 'contentful/bootstrap'
require 'tempfile'
require 'sequel'
require 'json'

# Top level space
module Contentful
  # Database Importer Tool
  module DatabaseImporter
    def self.config
      @config ||= Config.new
    end

    def self.setup
      yield config if block_given?

      raise 'Configuration is incomplete' unless config.complete?
    end

    def self.database
      error = 'Database Configuration not found'
      raise error if config.database_connection.nil?

      @database ||= ::Sequel.connect(config.database_connection)
    end

    def self.generate_json
      JsonGenerator.generate_json
    end

    def self.generate_json!
      JsonGenerator.generate_json!
    end

    def self.generate_json_file!
      file = Tempfile.new("import_#{config.space_name}")
      file.write(generate_json!)
      file.close
      file
    end

    def self.bootstrap_create_space!(file)
      Contentful::Bootstrap::CommandRunner.new.create_space(
        config.space_name,
        locale: config.locale,
        json_template: file.path
      )
    ensure
      file.unlink
    end

    def self.bootstrap_update_space!(file)
      Contentful::Bootstrap::CommandRunner.new.update_space(
        config.space_id,
        environment: config.environment,
        locale: config.locale,
        json_template: file.path,
        skip_content_types: config.skip_content_types
      )
    ensure
      file.unlink
    end

    def self.run!
      raise 'Configuration is incomplete' unless config.complete_for_run?
      bootstrap_create_space!(generate_json_file!)
    end

    def self.update_space!
      raise 'Configuration is incomplete' unless config.complete_for_update?
      bootstrap_update_space!(generate_json_file!)
    end
  end
end
