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

  # Simplistic WHERE for test purposes
  # only supporting AND and = operators
  def string_where(query)
    matches = {}
    parts = query.downcase.split('and').map(&:strip)
    parts.each do |p|
      p_parts = p.split('=').map(&:strip)
      matches[p_parts[0].to_sym] = p_parts[1].gsub('"', '')
    end

    hash_where(matches)
  end

  def hash_where(matches)
    return all if matches.empty?

    all.select do |row|
      match = true
      matches.each do |k, v|
        match = false unless row[k] == v
      end

      match
    end
  end

  def where(matches = nil)
    return TableDouble.new(name, all) if matches.nil?

    fetched_rows = []
    case matches
    when String
      fetched_rows = string_where(matches)
    when Hash
      fetched_rows = hash_where(matches)
    end

    TableDouble.new(name, fetched_rows)
  end

  def map
    rows.map do |row|
      yield row if block_given?
    end
  end

  def first
    rows.first
  end

  def all
    rows
  end

  alias to_a all
end
