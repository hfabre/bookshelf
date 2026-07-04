namespace :cleanup do
  desc "Delete series and authors that no longer have any books"
  task orphans: :environment do
    series = Serie.without_books.destroy_all
    authors = Author.without_books.destroy_all

    puts "Deleted #{series.size} empty series and #{authors.size} empty authors"
  end
end
