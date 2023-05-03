class ElasticsearchDeleteJob < ApplicationJob
  def perform(elasticsearch_id)
    unless ENV["ELASTICSEARCH_URL"].present?
      Rails.logger.warn "ElasticsearchDeleteJob skipped, ELASTICSEARCH_URL is not set"
      return
    end

    Elasticsearch.delete(elasticsearch_id)
  end
end
