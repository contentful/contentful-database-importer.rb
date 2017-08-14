module Contentful
  module DatabaseImporter
    # Helpers
    module Support
      def self.snake_case(string)
        string.gsub(/::/, '/')
              .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr('-', '_')
              .downcase
      end

      def self.deep_hash_merge(hash1, hash2)
        result = {}
        hash1.each do |key, value|
          value2 = hash2[key]
          result[key] = merge(value, value2)
        end

        hash2.each do |key, value|
          next if hash1.keys.include?(key)
          result[key] = value
        end

        result
      end

      def self.merge(value, value2)
        if value.is_a?(::Hash) && value2.is_a?(::Hash)
          deep_hash_merge(value, value2)
        elsif value.is_a?(::Array) && value2.is_a?(::Array)
          value + value2
        else
          value || value2
        end
      end
    end
  end
end
