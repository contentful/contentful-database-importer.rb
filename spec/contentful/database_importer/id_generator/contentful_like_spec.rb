require 'spec_helper'

describe Contentful::DatabaseImporter::IdGenerator::ContentfulLike do
  describe '#run' do
    it 'encodes using Base62' do
      expect(subject.run(EntryDataDouble.new(foo: 'bar'), 1)).to match(/[a-zA-Z0-9]+/)
    end
  end
end
