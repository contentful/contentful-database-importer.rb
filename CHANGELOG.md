# CHANGELOG

## Unreleased

## 0.6.0
### Added
* Added support for `Time` coercion. [#21](https://github.com/contentful/contentful-database-importer.rb/pull/21)

## 0.5.0
### Added
* Support for environments.

## 0.4.0

### Added
* Added possibility to specify `locale` for Space creation and update.

## 0.3.3

### Added
* Added notice on using Sequel `v5` when requiring string literals on queries or namespaces. [#12](https://github.com/contentful/contentful-database-importer.rb/issues/12)

### Fixed
* Fixed Merge tables not properly working.

## 0.3.2

### Fixed
* Excluded Fields are no longer part of the Content Type definition
* Display Fields no longer take into account excluded fields
* Asset IDs no longer contain non-valid characters

## 0.3.1

### Fixed
* Fixed issue when serializing non-reference arrays

## 0.3.0

### Changed
* Updated Contentful Bootstrap Version

### Fixed
* Fix Rubocop Offenses

### Added
* Support for `:object` field type

## 0.2.0

### Added
* Added `::update_space!` command - [#2](https://github.com/contentful/contentful-database-importer.rb/issues/2)
* Added `:skip_content_types` configuration option for `::update_space!`
* Added `::query` support on `Resource` for selecting specific content for a table

## 0.1.0

Initial version which includes all the basic features including:

* Major Databases Support
* Database to Content Type Mapping
* Field-level transformations
* Contentful Bootstrap JSON Generation
* Space creation
