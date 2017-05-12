module Contentful
  module DatabaseImporter
    # Bootstrap related Class Methods
    module ResourceBootstrapClassMethods
      TYPE_MAPPINGS = {
        symbol: 'Symbol',
        text: 'Text',
        date: 'Date',
        object: 'Object',
        location: 'Location',
        link: 'Link',
        integer: 'Integer',
        number: 'Number',
        boolean: 'Boolean'
      }.freeze

      def definition_type(type)
        if type == :string
          type = :symbol
        elsif link?(type)
          type = :link
        end

        TYPE_MAPPINGS[type]
      end

      def link_type(type)
        return 'Asset' if type == :asset
        return 'Entry' if resource?(type)

        raise 'Type class is not a valid Link'
      end

      def items_type(field_data)
        return { type: 'Link', linkType: array_link_type(field_data) } if array_link?(field_data)

        type = definition_type(field_data[:item_type])

        error = 'Array item type could not be mapped for '
        error += field_data[:maps_to].to_s
        raise error if type.nil?

        { type: type }
      end

      def array_link?(field_data)
        (field_data[:type] == :array && field_data[:item_type] == :asset) ||
          (resource?(field_data[:type]) &&
           [:many, :through].include?(field_data[:relationship]))
      end

      def array_link_type(field_data)
        return 'Asset' if field_data[:item_type] == :asset
        return 'Entry' if resource?(field_data[:type])
      end

      def link?(type)
        type == :asset || resource?(type)
      end

      def array?(field_data)
        field_data[:type] == :array ||
          (resource?(field_data[:type]) &&
           [:many, :through].include?(field_data[:relationship]))
      end

      def resource?(other)
        return false unless other.respond_to?(:ancestors)
        other.ancestors.include?(::Contentful::DatabaseImporter::Resource)
      end

      def link_type?(field_data)
        link?(field_data[:type]) && !array_link?(field_data)
      end

      def basic_field_definition(field_data)
        {
          id: field_data[:maps_to],
          name: field_data[:name],
          type: definition_type(field_data[:type])
        }
      end

      def field_definition(field_data)
        definition = basic_field_definition(field_data)

        definition[:type] = 'Array' if array?(field_data)
        definition[:linkType] = link_type(field_data[:type]) if link_type?(field_data)
        definition[:items] = items_type(field_data) if array?(field_data)

        definition
      end

      def fields_definition
        fields.reject { |f| f[:exclude_from_output] }.map { |f| field_definition(f) }
      end

      def content_type_definition
        {
          id: content_type_id,
          name: content_type_name,
          displayField: display_field,
          fields: fields_definition
        }
      end
    end
  end
end
