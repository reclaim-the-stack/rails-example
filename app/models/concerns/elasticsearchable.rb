module Elasticsearchable
  extend ActiveSupport::Concern

  included do
    after_commit on: %i[create update], if: :should_index? do
      ElasticsearchIndexJob.perform_later(self.class.name, id)
    end

    after_commit on: :destroy do
      ElasticsearchDeleteJob.perform_later(elasticsearch_id)
    end
  end

  # Override this method to control when the model should be indexed
  def should_index?
    true
  end

  def elasticsearch_id
    "#{self.class.name}-#{id}"
  end

  def elasticsearch_title
    title
  end

  def elasticsearch_content
    raise NotImplementedError
  end
end
