require "test_helper"

class BookServices::LibraryBundleTest < ActiveSupport::TestCase
  let(:user) { users(:one) }

  it "yields each book grouped into a per-serie folder" do
    serie = user.series.create!(name: "The Expanse")
    user.books.create!(filename: "lev.epub", epub_content: "AAA", title: "Leviathan", serie: serie, serie_index: 1)
    user.books.create!(filename: "solo.epub", epub_content: "CCC", title: "Solo")

    entries = {}
    BookServices::LibraryBundle.new(user).each_entry { |path, content| entries[path] = content }

    _(entries["The Expanse/lev.epub"]).must_equal "AAA"
    _(entries["No Series/solo.epub"]).must_equal "CCC"
  end

  it "reports whether the user has any downloadable books" do
    _(BookServices::LibraryBundle.new(user).any?).must_equal true
    _(BookServices::LibraryBundle.new(users(:admin)).any?).must_equal false
  end
end
