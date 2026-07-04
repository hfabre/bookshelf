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

    it "does not raise on names containing FTS5-special punctuation" do
      serie = Serie.new(name: "Vol.2: A-B", user: users(:one))

      _(SerieServices::SimilarityService.new(serie).call.to_a).must_be_kind_of Array
    end

    it "ranks the most relevant match ahead of common-token matches within the limit" do
      user = users(:one)
      # noise sharing only the common stopword-like tokens "de"/"la"
      12.times { |i| user.series.create!(name: "Le Seigneur de la Guerre #{i}") }
      best = user.series.create!(name: "L'Âge de la folie")
      source = user.series.create!(name: "L'âge de la folie")
      Serie.rebuild_search_index

      results = SerieServices::SimilarityService.new(source).call(5)

      _(results).must_include best
    end
  end
end
