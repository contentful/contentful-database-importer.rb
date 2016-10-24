module Contentful
  module DatabaseImporter
    # Bootstrap related methods
    module ResourceBootstrapMethods
      def to_bootstrap
        {
          sys: {
            id: id
          },
          fields: bootstrap_fields
        }
      end

      def to_link
        {
          linkType: 'Entry',
          id: id
        }
      end
    end
  end
end
