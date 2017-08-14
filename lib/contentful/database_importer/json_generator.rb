require 'json'

module Contentful
  module DatabaseImporter
    # Json File Generator
    module JsonGenerator
      def self.generate_json
        result = { version: 3, contentTypes: [],
                   assets: [], entries: {} }

        resources.each do |resource|
          content_type_definition = resource.content_type_definition
          create_content_type(content_type_definition, result)
          create_entries(resource, content_type_definition, result)
        end

        result
      end

      def self.resources
        ObjectSpace.each_object(Class).select do |c|
          c.included_modules.include? Resource
        end
      end

      def self.create_content_type(content_type_definition, result)
        prev_ct_definition = result[:contentTypes].find do |ct|
          ct[:id] == content_type_definition[:id]
        end

        if prev_ct_definition
          result[:contentTypes].delete(prev_ct_definition)
          content_type_definition = Support.merge(
            prev_ct_definition, content_type_definition
          )
        end

        result[:contentTypes] << content_type_definition
      end

      def self.create_entries(resource, content_type_definition, result)
        result[:entries][content_type_definition[:id]] ||= []
        resource.all.each do |entry|
          create_entry(entry, content_type_definition, result)
        end
      end

      def self.previous_entry(entry_definition, content_type_definition, result)
        result[:entries][content_type_definition[:id]].find do |e|
          e[:sys][:id] == entry_definition[:sys][:id]
        end
      end

      def self.merge_entries(entry_definition, content_type_definition, result)
        prev_entry = previous_entry(
          entry_definition,
          content_type_definition,
          result
        )

        return entry_definition unless prev_entry

        result[:entries][content_type_definition[:id]].delete(prev_entry)
        Support.merge(prev_entry, entry_definition)
      end

      def self.create_entry(entry, content_type_definition, result)
        entry_definition = entry.to_bootstrap

        entry_definition = merge_entries(entry_definition, content_type_definition, result)

        result[:assets].concat(entry.associated_assets) unless entry.associated_assets.empty?

        result[:entries][content_type_definition[:id]] << entry_definition
      end

      def self.generate_json!
        JSON.pretty_generate(generate_json)
      end
    end
  end
end
