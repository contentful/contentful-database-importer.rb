module Contentful
  module DatabaseImporter
    # Relationship methods for Resource
    module ResourceRelationships
      def fetch_relations(relationship_field_definition)
        relations = [:many, :one, :through]
        if relations.include?(relationship_field_definition[:relationship])
          return send(
            "fetch_#{relationship_field_definition[:relationship]}".to_sym,
            relationship_field_definition
          )
        end

        raise 'Invalid Relationship type'
      end

      def fetch_many(relationship_field_definition)
        table_name = relationship_field_definition[:type].table_name
        Contentful::DatabaseImporter.database[table_name].where(
          relationship_field_definition[:key] =>
            @raw[relationship_field_definition[:id_field]]
        ).map do |row|
          relationship_field_definition[:type].new(row).to_link
        end
      end

      def fetch_one(relationship_field_definition)
        table_name = relationship_field_definition[:type].table_name
        row = Contentful::DatabaseImporter.database[table_name].where(
          relationship_field_definition[:id_field] =>
            @raw[relationship_field_definition[:key]]
        ).first

        return if row.nil?

        relationship_field_definition[:type].new(row).to_link
      end

      def fetch_through_table_rows(relationship_field_definition)
        through_table_name = relationship_field_definition[:through]

        Contentful::DatabaseImporter.database[through_table_name].where(
          relationship_field_definition[:primary_key] =>
            @raw[relationship_field_definition[:primary_id_field]]
        ).to_a
      end

      def resolve_through_relationship(through_row, field_definition)
        table_name = field_definition[:type].table_name

        related = Contentful::DatabaseImporter.database[table_name].where(
          field_definition[:foreign_id_field] =>
            through_row[field_definition[:foreign_key]]
        ).first

        field_definition[:type].new(related).to_link
      end

      def fetch_through(relationship_field_definition)
        through = fetch_through_table_rows(relationship_field_definition)

        through.map do |through_row|
          resolve_through_relationship(
            through_row,
            relationship_field_definition
          )
        end
      end
    end
  end
end
