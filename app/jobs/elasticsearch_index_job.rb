class ElasticsearchIndexJob < ApplicationJob
  def perform(klass, id)
    unless ENV["ELASTICSEARCH_URL"].present?
      Rails.logger.warn "ElasticsearchIndexJob skipped, ELASTICSEARCH_URL is not set"
      return
    end

    model = klass.constantize.find_by_id(id)
    return unless model

    Elasticsearch.index(model)
  end
end
