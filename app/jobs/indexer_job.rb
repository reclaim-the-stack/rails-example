class IndexerJob < ApplicationJob
  def perform(operation, klass, id)
    klass = klass.constantize

    case operation
    when "create"
      model = klass.find_by_id(id)
      return unless model

      model.__elasticsearch__.index_document
    when /update/
      model = klass.find_by_id(id)
      return unless model

      model.__elasticsearch__.update_document
    when /delete/
      begin
        klass.__elasticsearch__.client.delete(index: klass.index_name, id: id)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound # rubocop:disable Lint/SuppressedException
      end
    else
      raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end
