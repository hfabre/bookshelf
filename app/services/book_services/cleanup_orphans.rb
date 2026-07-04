module BookServices
  # Deletes series/authors that no longer have any books, e.g. after the last
  # book of a serie/author is deleted or moved elsewhere. Safe to call with
  # stale records or duplicates: already-removed or still-referenced records
  # are skipped.
  class CleanupOrphans
    def self.call(records)
      Array(records).compact.uniq.each do |record|
        next unless record.class.exists?(record.id)

        record.destroy if record.books.reload.empty?
      end
    end
  end
end
