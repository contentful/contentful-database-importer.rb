
module Contentful
  module DatabaseImporter
    # Class Methods for Resource
    module ResourceClassMethods
      attr_accessor :id_generator

      def table_name
        (@table_name || Support.snake_case(name)).to_sym
      end

      def table_name=(name)
        @table_name = name
      end

      def content_type_id
        @content_type_id || Support.snake_case(name)
      end

      def content_type_id=(ct_id)
        @content_type_id = ct_id
      end

      def content_type_name
        (@content_type_name || name)
      end

      def content_type_name=(name)
        @content_type_name = name
      end

      def default_generator_options
        {
          table_name: table_name,
          content_type_id: content_type_id,
          class_name: name,
          template: '{{content_type_id}}_{{index}}'
        }
      end

      def id(id_generator_class, options = {})
        @id_generator = id_generator_class.new(
          default_generator_options.merge(options)
        )
      end

      def display_field
        @display_field || (fields.find do |f|
          f[:type] == :string || f[:type] == :symbol
        end || {})[:maps_to]
      end

      def display_field=(field_name)
        @display_field = field_name
      end

      def fields
        @fields || []
      end

      def relationship_fields
        @fields.select { |f| resource?(f[:type]) }
      end

      def prepare_standard_field_options(database_name, options)
        {
          db_name: database_name,
          maps_to: options.fetch(:maps_to, database_name),
          name: options.fetch(:name, database_name),
          type: options.fetch(:type),
          pre_process: options.fetch(:pre_process, nil),
          exclude_from_output: options.fetch(:exclude_from_output, false)
        }
      end

      def prepare_field(database_name, options)
        field = prepare_standard_field_options(database_name, options)
        field[:item_type] = options.fetch(:item_type) if field[:type] == :array
        fetch_relationship_options(
          field,
          options
        ) if options.fetch(:relationship, false)

        field
      end

      def field(database_name, options = {})
        @fields ||= []
        @fields << prepare_field(database_name, options)
      end

      def fetch_many_relationship_options(field, options)
        field[:id_field] = options.fetch(:id_field)
        field[:key] = options.fetch(:key)
      end
      alias fetch_one_relationship_options fetch_many_relationship_options

      def fetch_through_relationship_options(field, options)
        field[:through] = options.fetch(:through)
        field[:primary_id_field] = options.fetch(:primary_id_field)
        field[:foreign_id_field] = options.fetch(:foreign_id_field)
        field[:primary_key] = options.fetch(:primary_key)
        field[:foreign_key] = options.fetch(:foreign_key)
      end

      def fetch_relationship_options(field, options)
        field[:relationship] = options.fetch(:relationship)

        send(
          "fetch_#{options.fetch(:relationship)}_relationship_options",
          field,
          options
        )
      end

      def all
        entries = []
        rows = Contentful::DatabaseImporter.database[table_name].all
        rows.each_with_index do |row, index|
          entries << new(row, index)
        end
        entries
      end
    end
  end
end
