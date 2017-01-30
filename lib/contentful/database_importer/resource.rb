require 'contentful/database_importer/support'
require 'contentful/database_importer/resource_coercions'
require 'contentful/database_importer/resource_relationships'
require 'contentful/database_importer/resource_bootstrap_methods'
require 'contentful/database_importer/resource_class_methods'
require 'contentful/database_importer/resource_field_class_methods'
require 'contentful/database_importer/resource_bootstrap_class_methods'
require 'mimemagic'

module Contentful
  module DatabaseImporter
    # Resource for mapping Database Tables to
    # Contentful Content Types and Entries
    module Resource
      include ResourceCoercions
      include ResourceRelationships
      include ResourceBootstrapMethods

      def self.included(base)
        base.extend(ResourceClassMethods)
        base.extend(ResourceFieldClassMethods)
        base.extend(ResourceBootstrapClassMethods)
      end

      attr_reader :bootstrap_fields,
                  :excluded_fields,
                  :index,
                  :associated_assets

      def initialize(row, index = 0)
        @index = index
        @bootstrap_fields = {}
        @excluded_fields = {}
        @raw = row
        @associated_assets = []

        row.each do |db_name, value|
          process_row_field(db_name, value)
        end

        process_relationships
      end

      def process_row_field(db_name, value)
        field_definition = self.class.fields.find { |f| f[:db_name] == db_name }

        return unless field_definition

        value = pre_process(field_definition, value)
        value = coerce(field_definition, value)

        if field_definition[:exclude_from_output]
          @excluded_fields[field_definition[:maps_to]] = value
        else
          @bootstrap_fields[field_definition[:maps_to]] = value
        end
      end

      def process_relationships
        self.class.relationship_fields.each do |relationship_field_definition|
          relations = fetch_relations(relationship_field_definition)
          @bootstrap_fields[relationship_field_definition[:maps_to]] = relations
        end
      end

      def pre_process(field_definition, value)
        return value unless field_definition[:pre_process]

        transformation = field_definition[:pre_process]

        return send(transformation, value) if transformation.is_a? ::Symbol
        return transformation.call(value) if transformation.respond_to?(:call)

        raise
      rescue
        error = 'Pre Process could not be done for '
        error += "#{field_definition[:maps_to]} - #{transformation}"
        raise error
      end

      def id
        if self.class.id_generator.nil?
          self.class.id_generator = IdGenerator::Base.new(
            self.class.default_generator_options
          )
        end

        self.class.id_generator.run(self, index)
      end
    end
  end
end
