require "test_helper"

class SerieServices::SimilarityServiceTest < ActiveSupport::TestCase
  # Fixtures skip the after_commit callbacks that maintain the FTS index
  before { Serie.rebuild_search_index }

  describe "#call" do
    it "returns nothing when the serie name is blank" do
      serie = Serie.new(name: "", user: users(:one))

      _(SerieServices::SimilarityService.new(serie).call).must_be_empty
    end

    it "finds same-user series matching the name, excluding self and other users" do
      results = SerieServices::SimilarityService.new(series(:naruto)).call

      _(results).must_include series(:naruto_shippuden)
      _(results).wont_include series(:naruto)            # self
      _(results).wont_include series(:naruto_other_user) # different user
      _(results).wont_include series(:target)            # same user, no shared token
    end
  end
end
