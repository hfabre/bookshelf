class AuthorsController < ApplicationController
  def index
    @authors = current_user.authors.ordered
  end
end
