$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'contentful/database_importer'
require 'simplecov'

SimpleCov.start

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

class EntryDataDouble
  attr_reader :excluded_fields, :bootstrap_fields

  def initialize(excluded_fields = {}, bootstrap_fields = {})
    @excluded_fields = excluded_fields
    @bootstrap_fields = bootstrap_fields
  end
end

class DatabaseDouble
  attr_reader :tables

  def initialize(tables = [])
    @tables = tables
  end

  def [](table_name)
    tables.find { |t| t.name == table_name }
  end
end

class TableDouble
  attr_reader :name, :rows

  def initialize(name, rows = [])
    @name = name
    @rows = rows
  end

  def where(matches = {})
    return all if matches.empty?

    all.select do |row|
      match = true
      matches.each do |k, v|
        match = false unless row[k] == v
      end

      match
    end
  end

  def all
    rows
  end
end
