require 'spec_helper'

class FileDouble
  def write(*); end
  def close; end
  def unlink; end
  def path; 'foo'; end
end

describe Contentful::DatabaseImporter do
  before do
    described_class.instance_variable_set(:@config, Contentful::DatabaseImporter::Config.new)
  end

  it 'has a version number' do
    expect(Contentful::DatabaseImporter::VERSION).not_to be nil
  end

  describe 'class methods' do
    describe '::config' do
      it 'returns a default config when empty' do
        expect(described_class.config).to be_a Contentful::DatabaseImporter::Config
        expect(described_class.config.complete_for_run?).to be_falsey
      end

      it 'returns the settuped config when modified' do
        described_class.config.database_connection = 'foo'
        described_class.config.space_name = 'bar'

        expect(described_class.config.complete_for_run?).to be_truthy
      end
    end

    describe '::setup' do
      it 'yields a config for setup' do
        described_class.setup do |config|
          expect(config).to be_a Contentful::DatabaseImporter::Config
          config.space_name = 'foo'
          config.database_connection = 'bar'
        end

        expect(described_class.config.complete_for_run?).to be_truthy
      end

      it 'fails if configuration is not complete after setup' do
        expect {
          described_class.setup do |config|
          end
        }.to raise_error 'Configuration is incomplete'
      end
    end

    describe '::database' do
      it 'returns a database object' do
        expect(::Sequel).to receive(:connect) { DatabaseDouble.new }

        described_class.setup do |config|
          config.space_name = 'foo'
          config.database_connection = 'bar'
        end

        described_class.database
      end

      it 'fails if database configuration is not found' do
        expect { described_class.database }.to raise_error 'Database Configuration not found'
      end
    end

    describe '::generate_json' do
      it 'calls the JSON Generator' do
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json)
        described_class.generate_json
      end
    end

    describe '::generate_json!' do
      it 'calls the JSON Generator' do
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json!)
        described_class.generate_json!
      end
    end

    describe '::run!' do
      it 'calls bootstrap with the json in a tempfile' do
        file = FileDouble.new
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json!)
        expect(Tempfile).to receive(:new) { file }
        expect_any_instance_of(Contentful::Bootstrap::CommandRunner).to receive(:create_space).with('foo', locale: 'en-US', json_template: 'foo')

        described_class.setup do |config|
          config.space_name = 'foo'
          config.database_connection = 'bar'
        end

        described_class.run!
      end

      it 'can be called with a different locale' do
        file = FileDouble.new
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json!)
        expect(Tempfile).to receive(:new) { file }
        expect_any_instance_of(Contentful::Bootstrap::CommandRunner).to receive(:create_space).with('foo', locale: 'es-AR', json_template: 'foo')

        described_class.setup do |config|
          config.space_name = 'foo'
          config.database_connection = 'bar'
          config.locale = 'es-AR'
        end

        described_class.run!
      end

      it 'fails if not properly configured' do
        expect { described_class.run! }.to raise_error 'Configuration is incomplete'
      end
    end

    describe '::update_space!' do
      it 'calls bootstrap with the json in a tempfile' do
        file = FileDouble.new
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json!)
        expect(Tempfile).to receive(:new) { file }
        expect_any_instance_of(Contentful::Bootstrap::CommandRunner).to receive(:update_space).with('foo', locale: 'en-US', json_template: 'foo', skip_content_types: true)

        described_class.setup do |config|
          config.space_id = 'foo'
          config.database_connection = 'bar'
        end

        described_class.update_space!
      end

      it 'can be called with a different locale' do
        file = FileDouble.new
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json!)
        expect(Tempfile).to receive(:new) { file }
        expect_any_instance_of(Contentful::Bootstrap::CommandRunner).to receive(:update_space).with('foo', locale: 'es-AR', json_template: 'foo', skip_content_types: true)

        described_class.setup do |config|
          config.space_id = 'foo'
          config.database_connection = 'bar'
          config.locale = 'es-AR'
        end

        described_class.update_space!
      end

      it 'fails if not properly configured' do
        expect { described_class.update_space! }.to raise_error 'Configuration is incomplete'
      end
    end
  end
end
