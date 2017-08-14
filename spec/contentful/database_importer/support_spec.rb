require 'spec_helper'

describe Contentful::DatabaseImporter::Support do
  it '::snake_case' do
    expect(described_class.snake_case('Foo')).to eq 'foo'
    expect(described_class.snake_case('FooBar')).to eq 'foo_bar'
    expect(described_class.snake_case('foo')).to eq 'foo'
    expect(described_class.snake_case('foo_bar')).to eq 'foo_bar'
  end

  describe '::merge' do
    describe 'non hash or array pair' do
      it 'when 2 non nil values, grabs first' do
        expect(described_class.merge(1, 2)).to eq 1
      end

      it 'when 1 non nil value, grabs it' do
        expect(described_class.merge(1, nil)).to eq 1
        expect(described_class.merge(nil, 1)).to eq 1
      end

      it 'when both nil, nil' do
        expect(described_class.merge(nil, nil)).to eq nil
      end
    end

    describe 'when array pair' do
      it 'adds the elements in the array' do
        expect(described_class.merge([1, 2], [3, 4])).to eq [1, 2, 3, 4]
      end
    end

    describe 'when hash pair' do
      it 'does a deep_hash_merge of the hashes' do
        h1 = {foo: 'bar', bar: [1, 2], baz: {foobar: 1}}
        h2 = {bar: [3, 4], baz: {qux: 2}, quux: 'quuux'}

        expect(described_class.merge(h1, h2)).to eq({
          foo: 'bar',
          bar: [1, 2, 3, 4],
          baz: {foobar: 1, qux: 2},
          quux: 'quuux'
        })
      end
    end

    describe '::deep_hash_merge' do
      skip 'Already covered by merge'
    end
  end
end
