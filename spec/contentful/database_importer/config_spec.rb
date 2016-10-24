require 'spec_helper'

describe Contentful::DatabaseImporter::Config do
  describe 'instance attirubes' do
    it ':space_name' do
      expect(subject.space_name).to be nil

      subject.space_name = 'foo'

      expect(subject.space_name).to eq 'foo'
    end

    it ':database_connection' do
      expect(subject.database_connection).to be nil

      subject.database_connection = 'foo'

      expect(subject.database_connection).to eq 'foo'
    end
  end

  describe 'instance methods' do
    describe '#complete?' do
      it 'false when any attribute is missing' do
        expect(subject.complete?).to be_falsey

        subject.space_name = 'foo'

        expect(subject.complete?).to be_falsey

        subject.space_name = nil
        subject.database_connection = 'foo'

        expect(subject.complete?).to be_falsey
      end

      it 'true when both attributes are present' do
        subject.space_name = 'foo'
        subject.database_connection = 'foo'

        expect(subject.complete?).to be_truthy
      end
    end
  end
end
