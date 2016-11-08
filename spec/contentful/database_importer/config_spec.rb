require 'spec_helper'

describe Contentful::DatabaseImporter::Config do
  describe 'instance attirubes' do
    describe ':space_name' do
      it 'is nil by default' do
        expect(subject.space_name).to be nil
      end

      it 'can be overwritten' do
        subject.space_name = 'foo'

        expect(subject.space_name).to eq 'foo'
      end
    end

    describe ':space_id' do
      it 'is nil by default' do
        expect(subject.space_id).to be nil
      end

      it 'can be overwritten' do
        subject.space_id = 'foo'

        expect(subject.space_id).to eq 'foo'
      end
    end

    describe ':database_connection' do
      it 'is nil by default' do
        expect(subject.database_connection).to be nil
      end

      it 'can be overwritten' do
        subject.database_connection = 'foo'

        expect(subject.database_connection).to eq 'foo'
      end
    end

    describe ':skip_content_types' do
      it 'is false by default' do
        expect(subject.skip_content_types).to be_truthy
      end

      it 'can be overwritten' do
        subject.skip_content_types = false

        expect(subject.skip_content_types).to be_falsey
      end
    end
  end

  describe 'instance methods' do
    describe '#complete_for_run?' do
      it 'false when :space_name or :database_connection are missing' do
        expect(subject.complete_for_run?).to be_falsey

        subject.space_name = 'foo'

        expect(subject.complete_for_run?).to be_falsey

        subject.space_name = nil
        subject.database_connection = 'foo'

        expect(subject.complete_for_run?).to be_falsey
      end

      it 'true when both attributes are present' do
        subject.space_name = 'foo'
        subject.database_connection = 'foo'

        expect(subject.complete_for_run?).to be_truthy
      end
    end

    describe '#complete_for_update?' do
      it 'false when :space_id or :database_connection are missing' do
        expect(subject.complete_for_update?).to be_falsey

        subject.space_id = 'foo'

        expect(subject.complete_for_update?).to be_falsey

        subject.space_id = nil
        subject.database_connection = 'foo'

        expect(subject.complete_for_update?).to be_falsey
      end

      it 'true when both attributes are present' do
        subject.space_id = 'foo'
        subject.database_connection = 'foo'

        expect(subject.complete_for_update?).to be_truthy
      end
    end

    describe '#complete?' do
      it 'false when not complete_for_run or complete_for_update' do
        expect(subject.complete?).to be_falsey

        subject.space_id = 'foo'

        expect(subject.complete?).to be_falsey

        subject.space_name = 'foo'

        expect(subject.complete?).to be_falsey
      end

      it 'true when either is true' do
        subject.space_id = 'foo'
        subject.database_connection = 'foo'

        expect(subject.complete?).to be_truthy

        subject.space_id = nil
        subject.space_name = 'foo'

        expect(subject.complete?).to be_truthy

        subject.space_id = 'foo'

        expect(subject.complete?).to be_truthy
      end
    end
  end
end
