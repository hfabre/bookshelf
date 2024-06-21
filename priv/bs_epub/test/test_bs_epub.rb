# frozen_string_literal: true

require "test_helper"

describe BsEpub do
  it "has a version number" do
    _(::BsEpub::VERSION).wont_be_nil
  end
end
