class ElasticsearchDeleteJob < ApplicationJob
  def perform(elasticsearch_id)
    Elasticsearch.delete(elasticsearch_id)
  end
end
