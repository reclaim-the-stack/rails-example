class ElasticsearchIndexJob < ApplicationJob
  def perform(klass, id)
    model = klass.constantize.find_by_id(id)
    return unless model

    Elasticsearch.index(model)
  end
end
