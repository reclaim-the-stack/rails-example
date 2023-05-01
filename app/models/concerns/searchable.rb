# Description:
# Include this module in models that should be searchable.
#
# Models including the concern are expected to implement 'title' and 'searchable_content'
# for indexing. Title will be given higher priority compared to content.
#
# After adding and indexing your models. Search across all models can be performed via
# the Searchable.search method.

module Searchable
  extend ActiveSupport::Concern

  mattr_accessor :models
  self.models = []

  def self.search(query)
    return [] if query.blank?

    search_definition = {
      query: {
        multi_match: {
          query: query,
          fields: ["title^2", "content"],
        },
      },
    }

    Elasticsearch::Model.search(search_definition, models).records
  end

  def as_indexed_json(_options = {})
    {
      title: title,
      content: searchable_content,
    }
  end

  def should_index?
    true
  end

  def searchable_content
    raise NotImplementedError
  end

  included do
    include Elasticsearch::Model

    Searchable.models << self

    after_commit on: :create, if: :should_index? do
      IndexerJob.perform_later("create", self.class.name, id)
    end

    after_commit on: :update, if: :should_index? do
      IndexerJob.perform_later("update", self.class.name, id)
    end

    after_commit on: :destroy do
      IndexerJob.perform_later("delete", self.class.name, id)
    end

    settings index: { number_of_shards: 1 } do
      mappings dynamic: "false" do
        indexes :title, analyzer: "english", boost: 2
        indexes :content, analyzer: "english"
      end
    end
  end
end
