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

  # Override this method to control when the model should be indexed.
  # By default we skip indexing unless Sidekiq is connected to Redis
  # to avoid raising errors after commit.
  def should_index?
    Sidekiq.redis(&:info) rescue false
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
