module Contentful
  module DatabaseImporter
    module IdGenerator
      # Base Id Generator
      class Base
        attr_reader :options

        def initialize(options = {})
          @options = options
        end

        def run(entry_data, index)
          options.fetch(:template, '').gsub(/\{\{([\w|\.]+)\}\}/) do |match|
            find(entry_data, index, match.gsub('{{', '').gsub('}}', '').to_sym)
          end
        end

        def find(entry_data, index, match)
          return options[match] if options.key?(match)
          return index.to_s if match == :index

          find_on_entry(entry_data, match)
        end

        def find_on_entry(entry_data, match)
          if entry_data.excluded_fields.key?(match)
            return entry_data.excluded_fields[match]
          elsif entry_data.bootstrap_fields.key?(match)
            return entry_data.bootstrap_fields[match]
          end

          raise "Template could not be resolved, #{match} not found."
        end
      end
    end
  end
end
