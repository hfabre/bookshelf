require "test_helper"

class AuthorServices::SimilarityServiceTest < ActiveSupport::TestCase
  # Fixtures skip the after_commit callbacks that maintain the FTS index
  before { Author.rebuild_search_index }

  describe "#call" do
    it "returns nothing when the author name is blank" do
      author = Author.new(name: "", user: users(:one))

      _(AuthorServices::SimilarityService.new(author).call).must_be_empty
    end

    it "finds same-user authors matching the name, excluding self and other users" do
      results = AuthorServices::SimilarityService.new(authors(:sanderson)).call

      _(results).must_include authors(:brandon_mull)
      _(results).wont_include authors(:sanderson)          # self
      _(results).wont_include authors(:brandon_other_user) # different user
      _(results).wont_include authors(:tolkien)            # same user, no shared token
    end
  end
end
