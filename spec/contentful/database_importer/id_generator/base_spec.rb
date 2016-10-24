require 'spec_helper'

describe Contentful::DatabaseImporter::IdGenerator::Base do
  describe 'instance methods' do
    describe '#run' do
    end

    describe '#find' do
      subject { described_class.new(foo: 'bar') }

      it 'finds within generator options' do
        expect(subject.find(EntryDataDouble.new, 0, :foo)).to eq 'bar'
      end

      it 'returns index when match is :index' do
        expect(subject.find(EntryDataDouble.new, 123, :index)).to eq '123'
      end

      it 'returns value within excluded fields' do
        expect(subject.find(EntryDataDouble.new({bar: 'baz'}, {}), 0, :bar)).to eq 'baz'
      end

      it 'returns value within bootstrap fields' do
        expect(subject.find(EntryDataDouble.new({}, {bar: 'baz'}), 0, :bar)).to eq 'baz'
      end

      describe 'match priorities' do
        subject { described_class.new(foo: 'foo_options') }

        it 'options > index > excluded_fields > bootstrap_fields' do
          expect(subject.find(
            EntryDataDouble.new(
              {foo: 'foo_excluded', bar: 'bar_excluded', index: 'index_excluded'},
              {foo: 'foo_bootstrap', bar: 'bar_bootstrap', baz: 'baz_bootstrap', index: 'index_bootstrap'}
            ), 0, :foo)
          ).to eq 'foo_options'

          expect(subject.find(
            EntryDataDouble.new(
              {foo: 'foo_excluded', bar: 'bar_excluded', index: 'index_excluded'},
              {foo: 'foo_bootstrap', bar: 'bar_bootstrap', baz: 'baz_bootstrap', index: 'index_bootstrap'}
            ), 0, :index)
          ).to eq '0'

          expect(subject.find(
            EntryDataDouble.new(
              {foo: 'foo_excluded', bar: 'bar_excluded', index: 'index_excluded'},
              {foo: 'foo_bootstrap', bar: 'bar_bootstrap', baz: 'baz_bootstrap', index: 'index_bootstrap'}
            ), 0, :bar)
          ).to eq 'bar_excluded'

          expect(subject.find(
            EntryDataDouble.new(
              {foo: 'foo_excluded', bar: 'bar_excluded', index: 'index_excluded'},
              {foo: 'foo_bootstrap', bar: 'bar_bootstrap', baz: 'baz_bootstrap', index: 'index_bootstrap'}
            ), 0, :baz)
          ).to eq 'baz_bootstrap'
        end
      end

      it 'fails if field not found' do
        expect { subject.find(EntryDataDouble.new, 0, :bar) }.to raise_error 'Template could not be resolved, bar not found.'
      end
    end

    describe '#run' do
      subject { described_class.new(template: '{{from_opts}}_{{from_excluded}}_{{from_bootstrap}}_{{index}}', from_opts: 'opts') }

      it 'replaces values with the appropiate sources' do
        expect(subject.run(EntryDataDouble.new({from_excluded: 'excluded'}, {from_bootstrap: 'bootstrap'}), 123)).to eq 'opts_excluded_bootstrap_123'
      end
    end
  end
end
