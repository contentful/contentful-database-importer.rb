require 'spec_helper'

class NilMockResource
  include Contentful::DatabaseImporter::Resource
end

class MockResource
  include Contentful::DatabaseImporter::Resource

  field :foo, type: :string
  field :bar, type: :string
end

class OverridesMockResource
  include Contentful::DatabaseImporter::Resource

  self.table_name = 'foo'
  self.content_type_id = 'bar'
  self.content_type_name = 'Foo Bar'
  self.display_field = :bar

  field :foo, type: :string
  field :bar, type: :string
end

class MapsToMockResource
  include Contentful::DatabaseImporter::Resource

  field :foo, maps_to: :bar, type: :string
  field :baz, type: :string
end

class RelationshipsMockResource
  include Contentful::DatabaseImporter::Resource

  field :many, type: MockResource, relationship: :many, id_field: :id, key: :foo_id
  field :one, type: MockResource, relationship: :one, id_field: :id, key: :bar_id
  field :through, type: MockResource, relationship: :through,
    through: :foo_bar,
    primary_id_field: :id, primary_key: :foo_id,
    foreign_id_field: :id, foreign_key: :bar_id
end

class ArrayMockResource
  include Contentful::DatabaseImporter::Resource

  field :foo, type: :array, item_type: :string
  field :bar, type: :array, item_type: :asset
end

class RelationForeignTestMockResource
  include Contentful::DatabaseImporter::Resource

  self.table_name = 'foreign'

  id Contentful::DatabaseImporter::IdGenerator::Base, template: '{{table_name}}_{{id}}'

  field :id, type: :integer, exclude_from_output: true
  field :foo, type: :string
end

class RelationPrimaryTestMockResource
  include Contentful::DatabaseImporter::Resource

  self.table_name = 'primary'

  id Contentful::DatabaseImporter::IdGenerator::Base, template: '{{table_name}}_{{id}}'

  field :id, type: :integer, exclude_from_output: true
  field :foo, type: :string
  field :foreign_one, type: RelationForeignTestMockResource, relationship: :one, id_field: :id, key: :foreign_id
  field :foreign_many, type: RelationForeignTestMockResource, relationship: :many, id_field: :id, key: :primary_id
  field :foreign_through, type: RelationForeignTestMockResource, relationship: :through,
    through: :primary_foreign,
    primary_id_field: :id, primary_key: :primary_id,
    foreign_id_field: :id, foreign_key: :foreign_id
end

class AssetMockResource
  include Contentful::DatabaseImporter::Resource

  self.table_name = 'assets'

  field :foo, type: :string
  field :image, type: :asset
end

class PreProcessMockResource
  include Contentful::DatabaseImporter::Resource

  self.table_name = 'pre'

  field :foo, type: :string, pre_process: -> (value) { "hola_#{value}" }
  field :bar, type: :string, pre_process: :pre_bar

  def pre_bar(value)
    "chau_#{value}"
  end
end

class PreProcessFailMockResource
  include Contentful::DatabaseImporter::Resource

  field :foo, type: :string, pre_process: :failure
end

class AllTypesMockResource
  include Contentful::DatabaseImporter::Resource

  self.table_name = 'all'

  field :symbol, type: :symbol
  field :string, type: :string
  field :text, type: :text
  field :number, type: :number
  field :integer, type: :integer
  field :location, type: :location
  field :date, type: :date
  field :asset, type: :asset
  field :boolean, type: :boolean
  field :array, type: :array, item_type: :string
end

class ErrorTypesMockResource
  include Contentful::DatabaseImporter::Resource

  self.table_name = 'object'

  field :foo, type: :string
  field :object, type: :object
  field :array, type: :array, item_type: :array
end

describe Contentful::DatabaseImporter::Resource do
  describe 'class methods' do
    describe '::table_name' do
      it 'without override matches snake_case version of class name' do
        expect(MockResource.table_name).to eq :mock_resource
      end

      it 'with override matches override value' do
        expect(OverridesMockResource.table_name).to eq :foo
      end
    end

    describe '::content_type_id' do
      it 'without override matches snake_case version of class name' do
        expect(MockResource.content_type_id).to eq 'mock_resource'
      end

      it 'with override matches override value' do
        expect(OverridesMockResource.content_type_id).to eq 'bar'
      end
    end

    describe '::content_type_name' do
      it 'without override matches the class name' do
        expect(MockResource.content_type_name).to eq 'MockResource'
      end

      it 'with override matches override value' do
        expect(OverridesMockResource.content_type_name).to eq 'Foo Bar'
      end
    end

    describe '::display_field' do
      it 'returns nil when no overrides or string/symbol fields present' do
        expect(NilMockResource.display_field).to be_nil
      end

      it 'returns the first available string/symbol field' do
        expect(MockResource.display_field).to eq :foo
      end

      it 'returns the override value when set' do
        expect(OverridesMockResource.display_field).to eq :bar
      end

      it 'returns the maps_to value if present' do
        expect(MapsToMockResource.display_field).to eq :bar
      end
    end

    describe '::id' do
      it 'overrides the default id generator' do
        expect(MockResource.id_generator).to be_nil
        expect(RelationPrimaryTestMockResource.id_generator).to be_a Contentful::DatabaseImporter::IdGenerator::Base
        expect(RelationPrimaryTestMockResource.id_generator.options).to include(template: '{{table_name}}_{{id}}')
      end
    end

    describe '::fields' do
      it 'returns the fields declared in the class using ::field' do
        expect(NilMockResource.fields.size).to eq 0
        expect(MockResource.fields.size).to eq 2
        expect(OverridesMockResource.fields.size).to eq 2
      end
    end

    describe '::relationship_fields' do
      it 'returns fields with relationship data' do
        expect(MockResource.relationship_fields.size).to eq 0
        expect(RelationshipsMockResource.relationship_fields.size).to eq 3
      end
    end

    describe '::field' do
      let(:expected) { {
        db_name: :foo,
        maps_to: :bar,
        name: :foo,
        type: :string,
        pre_process: nil,
        exclude_from_output: false
      } }

      it 'creates a field definition' do
        expect(MapsToMockResource.fields.first).to eq expected
      end

      describe 'relationships' do
        describe ':many' do
          it 'fetches :id_field and :key' do
            expected[:db_name] = :many
            expected[:maps_to] = :many
            expected[:name] = :many
            expected[:relationship] = :many
            expected[:type] = MockResource
            expected[:id_field] = :id
            expected[:key] = :foo_id

            expect(RelationshipsMockResource.fields[0]).to eq expected
          end
        end

        describe ':one' do
          it 'fetches :id_field and :key' do
            expected[:db_name] = :one
            expected[:maps_to] = :one
            expected[:name] = :one
            expected[:relationship] = :one
            expected[:type] = MockResource
            expected[:id_field] = :id
            expected[:key] = :bar_id

            expect(RelationshipsMockResource.fields[1]).to eq expected
          end
        end

        describe ':through' do
          it 'fetches :through, :primary_id_field, :primary_key, :foreign_id_field and :foreign_key' do
            expected[:db_name] = :through
            expected[:maps_to] = :through
            expected[:name] = :through
            expected[:relationship] = :through
            expected[:type] = MockResource
            expected[:through] = :foo_bar
            expected[:primary_id_field] = :id
            expected[:primary_key] = :foo_id
            expected[:foreign_id_field] = :id
            expected[:foreign_key] = :bar_id

            expect(RelationshipsMockResource.fields[2]).to eq expected
          end
        end
      end
    end

    describe '::definition_type' do
      it 'basic types' do
        matches = {
          string: 'Symbol',
          symbol: 'Symbol',
          text: 'Text',
          date: 'Date',
          object: 'Object',
          location: 'Location',
          link: 'Link',
          integer: 'Integer',
          number: 'Number',
          boolean: 'Boolean',
          asset: 'Link'
        }

        matches.each do |type, expected|
          expect(MockResource.definition_type(type)).to eq expected
        end
      end

      it 'resource classes are Link' do
        expect(MockResource.definition_type(MockResource)).to eq 'Link'
      end
    end

    describe '::link_type' do
      it 'assets' do
        expect(MockResource.link_type(:asset)).to eq 'Asset'
      end

      it 'resources are Entry' do
        expect(MockResource.link_type(MockResource)).to eq 'Entry'
      end

      it 'fails on unknown link type' do
        expect { MockResource.link_type(123) }.to raise_error 'Type class is not a valid Link'
      end
    end

    describe '::items_type' do
      it 'basic types' do
        matches = {
          string: 'Symbol',
          symbol: 'Symbol',
          text: 'Text',
          date: 'Date',
          object: 'Object',
          location: 'Location',
          link: 'Link',
          integer: 'Integer',
          number: 'Number',
          boolean: 'Boolean',
          asset: 'Link'
        }

        matches.each do |type, expected|
          expect(MockResource.items_type(item_type: type)).to eq expected
        end
      end

      it 'links' do
        expect(MockResource.items_type(type: :array, item_type: :asset)).to eq(type: 'Link', linkType: 'Asset')
        expect(MockResource.items_type(type: MockResource, relationship: :many)).to eq(type: 'Link', linkType: 'Entry')
        expect(MockResource.items_type(type: MockResource, relationship: :through)).to eq(type: 'Link', linkType: 'Entry')
      end

      it 'fails on other cases' do
        expect { MockResource.items_type(maps_to: :foobar, item_type: :foo) }.to raise_error 'Array item type could not be mapped for foobar'
      end
    end

    describe '::link?' do
      it 'true when Asset or Resource' do
        expect(MockResource.link?(:asset)).to be_truthy
        expect(MockResource.link?(MockResource)).to be_truthy
      end

      it 'false when other' do
        expect(MockResource.link?(123)).to be_falsey
      end
    end

    describe '::array_link?' do
      it 'true when array and asset' do
        expect(MockResource.array_link?(type: :array, item_type: :asset)).to be_truthy
      end

      it 'true when :many or :through relationship' do
        expect(MockResource.array_link?(type: MockResource, relationship: :many)).to be_truthy
        expect(MockResource.array_link?(type: MockResource, relationship: :through)).to be_truthy
      end

      it 'false otherwise' do
        expect(MockResource.array_link?(type: :array, item_type: :string)).to be_falsey
        expect(MockResource.array_link?(type: MockResource, relationship: :one)).to be_falsey
      end
    end

    describe '::resource?' do
      it 'true when Resource' do
        expect(MockResource.resource?(MockResource)).to be_truthy
      end

      it 'false when other' do
        expect(MockResource.resource?(Array)).to be_falsey
      end
    end

    describe '::array?' do
      it 'true when :array or :many/:through relationships' do
        expect(MockResource.array?({type: :array})).to be_truthy
        expect(MockResource.array?({type: MockResource, relationship: :many})).to be_truthy
        expect(MockResource.array?({type: MockResource, relationship: :through})).to be_truthy
      end

      it 'false when other type or :one relationships' do
        expect(MockResource.array?({type: :string})).to be_falsey
        expect(MockResource.array?({type: MockResource, relationship: :one})).to be_falsey
      end
    end

    describe '::field_definition' do
      it 'creates a bootstrap compatible field definition' do
        expected = {
          id: :foo,
          name: :foo,
          type: 'Symbol'
        }
        expect(MockResource.field_definition(MockResource.fields[0])).to eq expected
      end

      it 'uses :maps_to for the field id over the :db_name' do
        expected = {
          id: :bar,
          name: :foo,
          type: 'Symbol'
        }
        expect(MockResource.field_definition(MapsToMockResource.fields[0])).to eq expected
      end

      describe 'arrays' do
        it 'basic type' do
          expected = {
            id: :foo,
            name: :foo,
            type: 'Array',
            items: 'Symbol'
          }
          expect(MockResource.field_definition(ArrayMockResource.fields[0])).to eq expected
        end

        it 'assets' do
          expected = {
            id: :bar,
            name: :bar,
            type: 'Array',
            items: {
              type: 'Link',
              linkType: 'Asset'
            }
          }
          expect(MockResource.field_definition(ArrayMockResource.fields[1])).to eq expected
        end

      end

      describe 'relationships' do
        it ':many' do
          expected = {
            id: :many,
            name: :many,
            type: 'Array',
            items: {
              type: 'Link',
              linkType: 'Entry'
            }
          }
          expect(MockResource.field_definition(RelationshipsMockResource.fields[0])).to eq expected
        end

        it ':one' do
          expected = {
            id: :one,
            name: :one,
            type: 'Link',
            linkType: 'Entry'
          }
          expect(MockResource.field_definition(RelationshipsMockResource.fields[1])).to eq expected
        end

        it ':through' do
          expected = {
            id: :through,
            name: :through,
            type: 'Array',
            items: {
              type: 'Link',
              linkType: 'Entry'
            }
          }
          expect(MockResource.field_definition(RelationshipsMockResource.fields[2])).to eq expected
        end
      end
    end

    describe '::fields_definition' do
      it 'returns field definition for all fields' do
        expect(NilMockResource.fields_definition.size).to eq 0
        expect(MockResource.fields_definition.size).to eq 2
        expect(RelationshipsMockResource.fields_definition.size).to eq 3

        expect(RelationshipsMockResource.fields_definition).to eq [
          RelationshipsMockResource.field_definition(RelationshipsMockResource.fields[0]),
          RelationshipsMockResource.field_definition(RelationshipsMockResource.fields[1]),
          RelationshipsMockResource.field_definition(RelationshipsMockResource.fields[2])
        ]
      end
    end

    describe '::content_type_definition' do
      it 'returns the bootstrap definition for the content type defined by the class' do
        expected = {
          id: MockResource.content_type_id,
          name: MockResource.content_type_name,
          displayField: MockResource.display_field,
          fields: MockResource.fields_definition
        }

        expect(MockResource.content_type_definition).to eq expected
      end
    end

    describe '::all' do
      it 'fetches all values from the DB and transforms each row into a Resource object' do
        mock_resource_table = TableDouble.new(:mock_resource, [{foo: 'hola', bar: 'hallo'}, {foo: 'chau', bar: 'tchuss'}])
        mock_database = DatabaseDouble.new([mock_resource_table])

        allow(Contentful::DatabaseImporter).to receive(:database) { mock_database }

        expect(MockResource.all.size).to eq 2
        expect(MockResource.all.first).to be_a MockResource
        expect(MockResource.all.first.bootstrap_fields).to eq(foo: 'hola', bar: 'hallo')
      end

      it 'resolves relationships' do
        primary_resource_table = TableDouble.new(:primary, [{id: 1, foo: 'hola', foreign_id: 2}, {id: 2, foo: 'chau', foreign_id: 1}])
        foreign_resource_table = TableDouble.new(:foreign, [{id: 1, foo: 'hallo', primary_id: 2}, {id: 2, foo: 'tchuss', primary_id: 1}])
        through_resource_table = TableDouble.new(:primary_foreign, [{primary_id: 1, foreign_id: 1}, {primary_id: 1, foreign_id: 2}])
        mock_database = DatabaseDouble.new([primary_resource_table, foreign_resource_table, through_resource_table])

        allow(Contentful::DatabaseImporter).to receive(:database) { mock_database }

        expect(RelationPrimaryTestMockResource.all.size).to eq 2

        expect(RelationPrimaryTestMockResource.all.first.bootstrap_fields[:foreign_one]).to eq(id: 'foreign_2', linkType: 'Entry')
        expect(RelationPrimaryTestMockResource.all.first.bootstrap_fields[:foreign_many]).to eq [{id: 'foreign_2', linkType: 'Entry'}]
        expect(RelationPrimaryTestMockResource.all.first.bootstrap_fields[:foreign_through]).to eq [{id: 'foreign_1', linkType: 'Entry'}, {id: 'foreign_2', linkType: 'Entry'}]
      end
    end
  end

  describe 'instance attributes' do
    describe ':bootstrap_fields' do
      it 'contains the value of the fields for the bootstrap json' do
        entry = MapsToMockResource.new({foo: 'foo', baz: 'baz'})

        expect(entry.bootstrap_fields).to eq(bar: 'foo', baz: 'baz')
      end
    end

    describe ':excluded_fields' do
      it 'is empty when none fields are excluded' do
        entry = MockResource.new({foo: 'foo', bar: 'bar'})

        expect(entry.excluded_fields).to be_empty
      end

      it 'contains the values of the fields set as excluded' do
        primary_resource_table = TableDouble.new(:primary, [{id: 1, foo: 'hola', foreign_id: 2}, {id: 2, foo: 'chau', foreign_id: 1}])
        foreign_resource_table = TableDouble.new(:foreign, [{id: 1, foo: 'hallo', primary_id: 2}, {id: 2, foo: 'tchuss', primary_id: 1}])
        through_resource_table = TableDouble.new(:primary_foreign, [{primary_id: 1, foreign_id: 1}, {primary_id: 1, foreign_id: 2}])
        mock_database = DatabaseDouble.new([primary_resource_table, foreign_resource_table, through_resource_table])
        allow(Contentful::DatabaseImporter).to receive(:database) { mock_database }

        entry = RelationPrimaryTestMockResource.new({id: 123, foo: 'foo'})

        expect(entry.excluded_fields).to eq({id: 123})
      end
    end

    describe ':index' do
      it 'defaults to 0' do
        entry = MockResource.new({foo: 'foo', bar: 'bar'})

        expect(entry.index).to eq 0
      end

      it 'can be overwrote' do
        entry = MockResource.new({foo: 'foo', bar: 'bar'}, 1)

        expect(entry.index).to eq 1
      end
    end

    describe ':associated_assets' do
      it 'creates an associated asset, as well as the proper link in bootstrap fields' do
        assets_table = TableDouble.new(:assets, [{foo: 'bar', image: 'https://foo.com/bar.jpg'}])
        mock_database = DatabaseDouble.new([assets_table])
        allow(Contentful::DatabaseImporter).to receive(:database) { mock_database }

        asset_entry = AssetMockResource.all.first

        expect(asset_entry.associated_assets.size).to eq 1
        expect(asset_entry.associated_assets.first).to eq({
          id: 'bar',
          title: 'bar',
          file: {
            filename: 'bar',
            url: 'https://foo.com/bar.jpg',
            contentType: 'image/jpeg'
          }
        })
        expect(asset_entry.bootstrap_fields[:image]).to eq({
          linkType: 'Asset',
          id: 'bar'
        })
      end
    end
  end

  describe 'pre processing' do
    it 'can be a lambda' do
      pre_process_table = TableDouble.new(:pre, [{foo: 'foo', bar: 'bar'}])
      mock_database = DatabaseDouble.new([pre_process_table])
      allow(Contentful::DatabaseImporter).to receive(:database) { mock_database }

      entry = PreProcessMockResource.all.first

      expect(entry.bootstrap_fields[:foo]).to eq 'hola_foo'
    end

    it 'can be a symbol representing a method' do
      pre_process_table = TableDouble.new(:pre, [{foo: 'foo', bar: 'bar'}])
      mock_database = DatabaseDouble.new([pre_process_table])
      allow(Contentful::DatabaseImporter).to receive(:database) { mock_database }

      entry = PreProcessMockResource.all.first

      expect(entry.bootstrap_fields[:bar]).to eq 'chau_bar'
    end

    it 'fails if method not found' do
      expect { PreProcessFailMockResource.new({foo: 'bar'}) }.to raise_error 'Pre Process could not be done for foo - failure'
    end
  end

  describe 'coercions' do
    it 'symbol/string/text' do
      entry = AllTypesMockResource.new({symbol: 'symbol', string: 'string', text: 'text'})

      expect(entry.bootstrap_fields[:symbol]).to eq 'symbol'
      expect(entry.bootstrap_fields[:string]).to eq 'string'
      expect(entry.bootstrap_fields[:text]).to eq 'text'
    end

    describe 'number' do
      it 'can be coerced from a float' do
        entry = AllTypesMockResource.new({number: 1.23})

        expect(entry.bootstrap_fields[:number]).to eq 1.23
      end

      it 'can be coerced from a string' do
        entry = AllTypesMockResource.new({number: '1.23'})

        expect(entry.bootstrap_fields[:number]).to eq 1.23
      end
    end

    describe 'integer' do
      it 'can be coerced from an integer' do
        entry = AllTypesMockResource.new({integer: 123})

        expect(entry.bootstrap_fields[:integer]).to eq 123
      end

      it 'can be coerced from a string' do
        entry = AllTypesMockResource.new({integer: '123'})

        expect(entry.bootstrap_fields[:integer]).to eq 123
      end
    end

    describe 'array' do
      it 'can be coerced from an array' do
        entry = AllTypesMockResource.new({array: ['foo', 'bar']})

        expect(entry.bootstrap_fields[:array]).to eq ['foo', 'bar']
      end

      it 'can be coerced from a comma separated string' do
        entry = AllTypesMockResource.new({array: 'foo,bar'})

        expect(entry.bootstrap_fields[:array]).to eq ['foo', 'bar']
      end
    end

    describe 'location' do
      it 'can be coerced from a hash' do
        entry = AllTypesMockResource.new({location: {lat: -1.0, lon: 1.0}})

        expect(entry.bootstrap_fields[:location]).to eq(lat: -1.0, lon: 1.0)

        entry = AllTypesMockResource.new({location: {latitude: -1.0, longitude: 1.0}})

        expect(entry.bootstrap_fields[:location]).to eq(lat: -1.0, lon: 1.0)
      end

      it 'can be coerced from a comma separated string' do
        entry = AllTypesMockResource.new({location: '-1.0,1.0'})

        expect(entry.bootstrap_fields[:location]).to eq(lat: -1.0, lon: 1.0)
      end

      it 'can be coerced from a float array' do
        entry = AllTypesMockResource.new({location: [-1.0, 1.0]})

        expect(entry.bootstrap_fields[:location]).to eq(lat: -1.0, lon: 1.0)
      end

      it 'fails if other type' do
        expect { AllTypesMockResource.new({location: 123}) }.to raise_error "Can't coerce 123 to Location"
      end
    end

    describe 'date' do
      it 'can be coerced from a Date object' do
        date = Date.today
        entry = AllTypesMockResource.new({date: date})

        expect(entry.bootstrap_fields[:date]).to eq date.iso8601
      end

      it 'can be coerced from DateTime object' do
        datetime = DateTime.now
        entry = AllTypesMockResource.new({date: datetime})

        expect(entry.bootstrap_fields[:date]).to eq datetime.iso8601
      end

      it 'can be coerced from a String' do
        date = '2016-02-01'
        entry = AllTypesMockResource.new({date: date})

        expect(entry.bootstrap_fields[:date]).to eq date
      end

      it 'fails if other type' do
        expect { AllTypesMockResource.new({date: 123}) }.to raise_error "Can't coerce 123 to ISO8601 Date"
      end
    end

    describe 'asset' do
      xit 'coerce from string - already covered by other specs'

      it 'fails when other type' do
        expect { AllTypesMockResource.new({asset: 123}) }.to raise_error "Only URL Strings supported for Assets"
      end
    end

    describe 'boolean' do
      it 'coerces from booleans' do
        entry = AllTypesMockResource.new({boolean: true})

        expect(entry.bootstrap_fields[:boolean]).to eq true

        entry = AllTypesMockResource.new({boolean: false})

        expect(entry.bootstrap_fields[:boolean]).to eq false
      end

      it 'can coerce from any other object' do
        entry = AllTypesMockResource.new({boolean: 123})

        expect(entry.bootstrap_fields[:boolean]).to eq true
      end
    end

    describe 'invalid coercions' do
      it ':object type coercions are not supported by bootstrap' do
        expect { ErrorTypesMockResource.new({object: {foo: 'bar'}}) }.to raise_error 'Not yet supported by Contentful Bootstrap'
      end

      it ':array type cannot contain :array items' do
        expect { ErrorTypesMockResource.new({array: [['foo']]}) }.to raise_error "Can't coerce nested arrays"
      end
    end
  end
end
