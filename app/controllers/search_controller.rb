class SearchController < ApplicationController
  def index
    @results = Searchable.search(params[:query])
  end
end
