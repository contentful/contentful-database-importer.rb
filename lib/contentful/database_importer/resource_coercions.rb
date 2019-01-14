module Contentful
  module DatabaseImporter
    # Coercion methods for Resource
    module ResourceCoercions
      def coerce(field_definition, value)
        return if value.nil?

        type = field_definition[:type]

        return coerce_array(field_definition, value) if type == :array

        send("coerce_#{type}".to_sym, value)
      end

      def coerce_symbol(value)
        value.to_s
      end
      alias coerce_string coerce_symbol
      alias coerce_text coerce_symbol

      def coerce_number(value)
        value.to_f
      end

      def coerce_integer(value)
        value.to_i
      end

      def coerce_array(field_definition, value)
        item_type = field_definition[:item_type]

        raise "Can't coerce nested arrays" if item_type == :array

        value = value.split(',').map(&:strip) if value.is_a?(::String)
        value.map { |v| coerce({ type: item_type }, v) }
      end

      def coerce_hash_location(value)
        {
          lat: value.fetch(:lat, nil) || value.fetch(:latitude, nil),
          lon: value.fetch(:lon, nil) || value.fetch(:longitude, nil)
        }
      end

      def coerce_array_location(value)
        {
          lat: value[0],
          lon: value[1]
        }
      end

      def coerce_location(value)
        return coerce_hash_location(value) if value.is_a?(::Hash)

        return coerce_array_location(value) if value.is_a?(::Array)

        if value.is_a?(::String) && value.include?(',')
          parts = value.split(',').map(&:strip).map(&:to_f)
          return coerce_array_location(parts)
        end

        raise "Can't coerce #{value} to Location"
      end

      def coerce_boolean(value)
        # rubocop:disable Style/DoubleNegation
        !!value
        # rubocop:enable Style/DoubleNegation
      end

      def coerce_date(value)
        case value
        when Time, Date, DateTime
          value.iso8601
        when String
          value
        else
          raise "Can't coerce #{value} to ISO8601 Date"
        end
      end

      def coerce_object(value)
        return value if value.is_a?(::Hash)

        raise "Can't coerce #{value} to JSON Object"
      end

      def create_associated_asset(name, value)
        extension = value.split('.').last
        associated_assets << {
          id: asset_id_from_name(name),
          title: name,
          file: {
            filename: name,
            url: value,
            contentType: MimeMagic.by_extension(extension).type
          }
        }
      end

      def coerce_asset(value)
        raise 'Only URL Strings supported for Assets' unless value.is_a?(String)

        name = value.split('/').last.split('.').first

        create_associated_asset(name, value)

        {
          linkType: 'Asset',
          id: asset_id_from_name(name)
        }
      end

      def asset_id_from_name(name)
        Support.snake_case(name.gsub(/[^\w ]/i, '_'))[0...64]
      end
    end
  end
end
