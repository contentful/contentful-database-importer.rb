module Contentful
  module DatabaseImporter
    # Configuration for Importer
    class Config
      attr_accessor :space_name,
                    :space_id,
                    :database_connection,
                    :skip_content_types,
                    :locale

      def initialize
        @skip_content_types = true
        @locale = 'en-US'
      end

      def complete_for_run?
        !space_name.nil? && !database_connection.nil?
      end

      def complete_for_update?
        !space_id.nil? && !database_connection.nil?
      end

      def complete?
        complete_for_run? || complete_for_update?
      end
    end
  end
end
