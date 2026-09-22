class AddTrigramIndexesToJobs < ActiveRecord::Migration[8.1]
  def change
    # A leading-wildcard ILIKE '%term%' (Job.search_title / in_location)
    # can't use a plain btree index at all — Postgres has to scan every row.
    # pg_trgm's GIN index can actually serve a substring search, which matters
    # more now that search fires on every keystroke (live search).
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    remove_index :jobs, :title
    remove_index :jobs, :location

    add_index :jobs, :title, using: :gin, opclass: :gin_trgm_ops
    add_index :jobs, :location, using: :gin, opclass: :gin_trgm_ops
  end
end
