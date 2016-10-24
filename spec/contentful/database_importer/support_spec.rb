require 'spec_helper'

describe Contentful::DatabaseImporter::Support do
  it '::snake_case' do
    expect(described_class.snake_case('Foo')).to eq 'foo'
    expect(described_class.snake_case('FooBar')).to eq 'foo_bar'
    expect(described_class.snake_case('foo')).to eq 'foo'
    expect(described_class.snake_case('foo_bar')).to eq 'foo_bar'
  end
end
