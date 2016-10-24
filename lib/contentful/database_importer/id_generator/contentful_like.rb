require 'contentful/database_importer/id_generator/base'
require 'base62-rb'

module Contentful
  module DatabaseImporter
    module IdGenerator
      # Base62 Encoded Id Generator
      class ContentfulLike < Base
        def run(entry_data, index)
          result = ''
          id = super(entry_data, index)
          id.each_char do |c|
            result << c.ord.to_s
          end

          result << '9' while result.size < 40

          Base62.encode(result.to_i)
        end
      end
    end
  end
end
