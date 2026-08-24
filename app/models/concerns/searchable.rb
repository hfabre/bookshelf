# Keeps a model's FTS5 index in sync and searches it. The index is a virtual
# table named after the model's own table, e.g. series -> series_fts.
module Searchable
  extend ActiveSupport::Concern

  included do
    after_create_commit :add_to_search_index
    after_update_commit :refresh_search_index
    after_destroy_commit :remove_from_search_index
  end

  class_methods do
    def search_index
      "#{table_name}_fts"
    end

    # Repopulates the index from scratch. Needed whenever rows arrive without
    # the callbacks (fixtures, imports), and to clear rows an older bug left
    # behind, which is why it starts by emptying the table.
    def rebuild_search_index
      connection.execute("DELETE FROM #{search_index}")
      find_each { |record| record.send(:add_to_search_index) }
      connection.execute("INSERT INTO #{search_index}(#{search_index}) VALUES('rebuild')")
    end
  end

  # Same-user records sharing a word with this one, best match first.
  def similar(limit = 10)
    return self.class.none if name.blank?

    table = self.class.table_name
    index = self.class.search_index

    self.class
        .joins("JOIN #{index} ON #{table}.id = #{index}.rowid")
        .where("#{index} MATCH ? AND #{table}.user_id = ? AND #{table}.id != ?", search_tokens, user_id, id)
        .order(Arel.sql("bm25(#{index})"))
        .limit(limit)
  end

  private

  # Quoted so punctuation can't be read as FTS5 syntax, OR'd so any word matches.
  def search_tokens
    name.split(/[\s,]+/).reject(&:blank?).map { |token| %("#{token.gsub('"', '""')}") }.join(" OR ")
  end

  def add_to_search_index
    execute_index_sql "INSERT INTO #{self.class.search_index} (rowid, name, user_id) VALUES (?, ?, ?)",
                      id, name, user_id
  end

  # These are content-bearing fts5 tables, so a row is removed with a plain
  # DELETE. The 'delete' command this used to run only works on contentless
  # tables: here it raised, was swallowed, and left renamed and destroyed
  # records in the index.
  def remove_from_search_index
    execute_index_sql "DELETE FROM #{self.class.search_index} WHERE rowid = ?", id
  end

  def refresh_search_index
    return unless saved_change_to_name?

    transaction do
      remove_from_search_index
      add_to_search_index
    end
  end

  def execute_index_sql(sql, *binds)
    self.class.connection.execute(self.class.sanitize_sql([ sql, *binds ]))
  end
end
