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

    def self.run_bootstrap!(file, json)
      file.write(json)
      file.close

      Contentful::Bootstrap::CommandRunner.new.create_space(
        config.space_name,
        json_template: file.path
      )
    ensure
      file.unlink
    end

    def self.run!
      json = generate_json!

      file = Tempfile.new("import_#{config.space_name}")
      run_bootstrap!(file, json)
    end
  end
end
