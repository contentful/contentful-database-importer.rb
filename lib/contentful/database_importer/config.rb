module Contentful
  module DatabaseImporter
    # Configuration for Importer
    class Config
      attr_accessor :space_name, :database_connection

      def complete?
        !space_name.nil? && !database_connection.nil?
      end
    end
  end
end
