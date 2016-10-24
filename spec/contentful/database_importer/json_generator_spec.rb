require 'spec_helper'

class MockEntry
  include Contentful::DatabaseImporter::Resource

  field :foo, type: :string
  field :bar, type: :asset

  def self.all
    []
  end
end

describe Contentful::DatabaseImporter::JsonGenerator do
  let(:empty_bootstrap) { {
      version: 3,
      contentTypes: [],
      assets: [],
      entries: {}
    }
  }

  describe 'class methods' do
    describe '::generate_json' do
      it 'returns an empty bootstrap json if no classes present' do
        allow(ObjectSpace).to receive(:each_object) { [] }
        expect(described_class.generate_json).to eq empty_bootstrap
      end

      it 'adds the content type definition based on fields' do
        allow(ObjectSpace).to receive(:each_object) { [MockEntry] }
        expected = empty_bootstrap.dup
        expected[:contentTypes] << {
          id: 'mock_entry',
          name: 'MockEntry',
          displayField: :foo,
          fields: [{
            id: :foo,
            name: :foo,
            type: 'Symbol'
          },
          {
            id: :bar,
            name: :bar,
            type: 'Link',
            linkType: 'Asset'
          }]
        }
        expected[:entries]['mock_entry'] = []

        expect(described_class.generate_json).to eq expected
      end

      it 'adds the entries and assets' do
        allow(ObjectSpace).to receive(:each_object) { [MockEntry] }
        allow(MockEntry).to receive(:all) { [MockEntry.new({foo: 'bar', bar: 'https://foo.com/image.jpg'}, 0)] }

        expected = empty_bootstrap.dup
        expected[:contentTypes] << {
          id: 'mock_entry',
          name: 'MockEntry',
          displayField: :foo,
          fields: [{
            id: :foo,
            name: :foo,
            type: 'Symbol'
          },
          {
            id: :bar,
            name: :bar,
            type: 'Link',
            linkType: 'Asset'
          }]
        }
        expected[:assets] << {
          id: 'image',
          title: 'image',
          file: {
            filename: 'image',
            url: 'https://foo.com/image.jpg',
            contentType: 'image/jpeg'
          }
        }
        expected[:entries]['mock_entry'] = [
          {
            sys: {
              id: 'mock_entry_0'
            },
            fields: {
              foo: 'bar',
              bar: {
                id: 'image',
                linkType: 'Asset'
              }
            }
          }
        ]

        expect(described_class.generate_json).to eq expected
      end
    end

    describe '::generate_json!' do
      it 'returns a json string of the generated json' do
        allow(ObjectSpace).to receive(:each_object) { [] }
        expect(described_class.generate_json!).to eq JSON.pretty_generate(empty_bootstrap)
      end
    end
  end
end
