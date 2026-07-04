namespace :cleanup do
  desc "Delete series and authors that no longer have any books"
  task orphans: :environment do
    result = BookServices::CleanupOrphans.sweep

    puts "Deleted #{result[:series]} empty series and #{result[:authors]} empty authors"
  end
end
