
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

      def query
        @query
      end

      def query=(query)
        @query = query
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

      def table
        Contentful::DatabaseImporter.database[table_name]
      end

      def all
        entries = []
        rows = table.where(query).all
        rows.each_with_index do |row, index|
          entries << new(row, index)
        end
        entries
      end
    end
  end
end
