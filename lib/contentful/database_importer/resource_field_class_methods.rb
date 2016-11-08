module Contentful
  module DatabaseImporter
    # Field related Class Methods for Resource
    module ResourceFieldClassMethods
      def field(database_name, options = {})
        @fields ||= []
        @fields << prepare_field(database_name, options)
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
    end
  end
end
