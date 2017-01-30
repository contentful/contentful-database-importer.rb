# Contentful Database Importer

![TravisCI](https://travis-ci.org/contentful/contentful-database-importer.rb.svg?branch=master)

A simple DSL to define your database schemas, their relation to Contentful and import them to Contentful.

This gem is intended to be a replacement to [`database_exporter`](https://github.com/contentful/database-exporter.rb). _Warning_: Both gems are incompatible.

## Contentful

[Contentful](http://www.contentful.com) is a content management platform for web applications, mobile apps and connected devices.
It allows you to create, edit and manage content in the cloud and publish it anywhere via a powerful API.
Contentful offers tools for managing editorial teams and enabling cooperation between organizations.

## What does `contentful-database-importer` do?

`contentful-database-importer` let's you define mapping classes between your database and Contentful and allows
you to generate a JSON file that's a valid [`contentful_bootstrap`](https://github.com/contentful/contentful-bootstrap.rb) JSON Template,
or directly import to Contentful, creating a new space and using your data to populate the content.

## Requirements

* Ruby
* A Relational Database

## Installation

```bash
gem install contentful-database-importer
```

## Usage

* Create a new directory for your import configuration:

```bash
mkdir my_importer_dir && cd my_importer_dir
```

* Create a _`Gemfile`_ with the gem:

```ruby
source 'https://rubygems.org'

gem 'contentful-database-importer'
```

* Add to your _`Gemfile`_ the handler specific to your database (e.g.):

```ruby
gem 'pg' # if using Postgres
gem 'sqlite3' # if using SQLite
gem 'mysql' # if using MySQL
```

* Create your importer file, for example _`import.rb`_:

```ruby
require 'contentful/database_importer'

class MyTable
  include Contentful::DatabaseImporter::Resource

  # ... your schema definition ... (explained in next section)
end

# ... more table definitions ...

Contentful::DatabaseImporter.setup do |config|
  config.space_name = 'My Cool New Space'
  config.database_connection = 'postgres://user:pass@host:port'
end

Contentful::DatabaseImporter.run!
```

* Run your file:

```bash
bundle exec ruby import.rb
```

### Defining your Schema

```ruby
class MyTable
  include Contentful::DatabaseImporter::Resource

  self.table_name = 'overrides_table_name' # Optional - By default it's the class name in snake case. E.g. 'my_table'
  self.content_type_id = 'overrides_content_type_id' # Optional - By default it's the class name in snake case. E.g 'my_table'
  self.content_type_name = 'Overrides Name' # Optional - By default it's the class name

  id Contentful::DatabaseImporter::IdGenerator::Base, template: '{{content_type_id}}_{{foo}}_{{index}}' # Optional - By default it's the IdGenerator::Base(template: '{{content_type_id}}_{{index}}')

  field :foo, type: :string
  field :bar, maps_to: :not_bar, type: :string
  field :image, type: :asset
end
```

#### Overriding Table and Content Type ID

The methods `::table_name=` and `::content_type_id=` allow you to override the IDs for either the table or content type.
By default, they are a `snake_cased` version of the class name.

#### Defining the ID generator

You can define the ID generation strategy, there are 2 classes currently provided:

- `Contentful::DatabaseImporter::IdGenerator::Base`: Provides a very basic template engine for generating IDs, this is the default strategy.
- `Contentful::DatabaseImporter::IdGenerator::ContentfulLike`: Provides a Base62 encode that produces IDs similar to the Contentful provided ones,
  uses the `Base` strategy, then pads it to a minimum length and then Base62 encode it.

##### ID Templates

Theres a minimal template engine provided for the ID Generators.
A single template looks like `{{foo}}_{{bar}}` and works by replacing the values enclosed between `{{}}` with the corresponding value for each entry.

There are a few variables globally provided for every class (and will be looked up before the object fields):

- `class_name`: The name of the mapping class
- `table_name`: The defined table name (or the default)
- `content_type_id`: The defined content type ID (or the default)
- `index`: The position of the entry (0-based) on the database table

After those globally provided values, you can use the value for any field on the mapping class (using the `:maps_to` value if present).

For example, using the example template above, if the DB record looks like:

```ruby
{foo: 'something', bar: 'else', image: 'https://example.com/happycat.jpg'}
```

Then the resulting template will be `something_else`

**Note**: With relationships, it's useful to use a unique identifier value as part of the ID template.

#### Defining Fields

For defining the field you have the `::field(name, options = {})` method. It defines how to retrieve and later serialize the field.

The options are:

- `type: type_name`: **Required** for coercions. Types defined below.
- `maps_to: name`: **Optional**. Defaults to field name, and defines the field name in Contentful
- `pre_process: lambda_or_symbol`: **Optional**. Described below.
- `exclude_from_output: boolean`: **Optional**. Defaults to false. Defines if the field will not be uploaded to Contentful. Useful for ID generation.

##### Regular Field Types

- `:symbol`, `:string`: Short text field (255 characters maximum) in Contentful.
- `:text`: Long text field.
- `:number`: Floating point precision number.
- `:integer`: Integer number.
- `:boolean`: Boolean.
- `:location`: Geographical Location (can be coerced from a String, Hash or Array.)
- `:date`: An ISO8601 Date (can be coerced from a Date/DateTime object or String).
- `:object`: A JSON Object.
- `:asset`: A File description. A String containing the file URL needs to be provided.
- `:array`: An Array of elements.

In the case of using `:array`, an extra parameter `item_type: type` must be provided.

##### Relationship Field Types

If your data has a relationship field, the `type:` value will be the related class, and will require additional parameters specifying
the relationship type and keys for retrieving the appropiate data.

For example:

```ruby
class Foo
  field :bars, type: Bar, relationship: :many, id_field: :id, key: :foo_id
  field :baz, type: Baz, relationship: :one, id_field: :id, key: :baz_id
  field :quxs, type: Qux, relationship: :many_through, through: :foo_qux, primary_id_field: :id, primary_key: :foo_id, foreign_key: :qux_id, foreign_id_field: :id
end
```

In Contentful, relationships are unidirectional, and if you want bidirectional relationships, you need to declare them in both classes.

Relationship fields have the particularity that they don't require the `:maps_to` property, as Contentful will always use
the field name for the property in Contentful. You define the name of the field in the database with relationship specific parameters.

Relationship Types:

- `:many`: One to Many relationship, looks for all related objects of the associated class that match the value of the `:id_field` via the `:key`.
  In the example above, it will look for all `Bar` entries which have a `:foo_id` that match the value of `:id` for the current `Foo` entry.
- `:one`: One to One relationship, looks for the related object of the associated class that matches the value of the `:key` field in the current entry, with the value of `:id_field` in the related entry.
  In the example above, it will look for the `Baz` entry which has an ID that matches the value of `:baz_id` in the current entry.
- `:many_through`: Many to Many relationship, looks for the related object through an intermediate lookup table, after this it behaves like `:many`.
  In the example above, it will look for all `Qux` entries found in the intermediate table that match the current entry `:id` and looks it up via the `Qux`s `:id`.

**Note**: If you're using relationships, use a custom ID Generator template which includes a unique field for each entry,
that way, creating the links in Contentful will be successful. This requires including the field in the class definition.

For example: `'{{content_type_id}}_{{id}}'`

**Note**: Ruby requires a class to be defined before using it as a parameter, therefore, you should declare all classes that
are contained within others, before the one in which you use them. If you want to have circular relationships, you need to define a Merge Class pointing to the same table and content type as the desired class (defined below).

##### Pre-processing

If you want to transform your data before uploading to Contentful,
you can use the `:pre_process` parameter in the `::field` definition.

The pre-process value can be a lambda function (E.g. `-> (value) { value + 1 }`) or a symbol (E.g. `:pre_process_foo`).

If you use a lambda function, it must receive a single parameter and return a single value.

If you use a Symbol, it must match the name of a method defined within the class you're calling it from.
This method must receive a single parameter and return a single value.

### Merging Tables

You might want to merge the content of multiple tables into a single content type.

This is supported by default, but ensure that the classes have the same `content_type_id` defined and if you need to
merge the entries as well, that the ID generator template is set in a way that can match the values from the different classes.

In the case you want to create multiple content types from a single table, the same concepts apply.

In the case of circular references, you will have to create 2 or more classes pointing to the same table and content type, the same concepts apply.

**Note**: Merge classes require at least 1 field declared, even if it's excluded from output.

### Querying

You might want to reduce your datasets to specific subsets, in that case, you can use Querying to specify your subsets of data.

A query is an `SQL String`. E.g: `foo = 'bar' AND baz > 2`.

This is optional and can be specified in the Resource like follows:

```ruby
class MyResource
  include Contentful::DatabaseImporter::Resource

  self.query = "foo = 'bar' AND baz > 2"

  field :foo, type: :string
  field :baz, type: :integer
end
```

### Configuration

```ruby
Contentful::DatabaseImporter.setup do |config|
  config.space_name = 'My Cool New Space' # Required only for `::run!` - the destination space name
  config.space_id = 'aAbBcC123foo' # Required only for `::update_space!` - the destination space ID
  config.database_connection = 'postgres://user:pass@host:port' # Required - the DB Connection string
  config.skip_content_types = true # Optional (only for `::update_space!`) - defaults to `true` - Skips Content Type creation upon updating a space
end
```

`database_connection` allows the following Database URI Strings:

- **[Postgres (Section 31.1.1.2)](https://www.postgresql.org/docs/9.3/static/libpq-connect.html#LIBPQ-CONNSTRING)**: E.g. `'postgres://user:password@host:port/database_name'`.
- **SQlite**: E.g. `'sqlite://file_path.db'`.
- **MySQL**: E.g. `'mysql://user:password@host:post/database_name'`.

### Running the Import Tool

You can do any of the following operations:

* Generate a JSON Template as a Ruby Hash for reuse within the script:

```ruby
Contentful::DatabaseImporter.generate_json
```

* Generate JSON Template as a prettyfied JSON string:

```ruby
Contentful::DatabaseImporter.generate_json!
```

* Generate the JSON and Import it to Contentful (creates a Space with all the content):

```ruby
Contentful::DatabaseImporter.run!
```

* Generate the JSON and Import it to Contentful (updates a Space with all the content):

```ruby
Contentful::DatabaseImporter.update_space!
```

## Contributing

Feel free to improve this tool by submitting a Pull Request. For more information, please read [CONTRIBUTING.md](./CONTRIBUTING.md)
