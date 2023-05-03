class SearchController < ApplicationController
  def index
    @results = Elasticsearch.search(params[:query])
  end
end
