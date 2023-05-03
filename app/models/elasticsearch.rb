require "net/http"
require "json"

module Elasticsearch
  INDEX = "searchables".freeze

  def self.index(active_record_instance)
    connection_pool.with do |client|
      client.index(
        INDEX,
        active_record_instance.elasticsearch_id,
        title: active_record_instance.elasticsearch_title,
        content: active_record_instance.elasticsearch_content,
        updated_at: active_record_instance.updated_at,
        created_at: active_record_instance.created_at,
      )
    end
  end

  def self.delete(id)
    connection_pool.with do |client|
      client.delete(INDEX, id)
    end
  end

  def self.search(query)
    return [] if query.blank?

    result = connection_pool.with do |client|
      client.search(
        INDEX,
        _source: false,
        stored_fields: %w[_id],
        query: {
          multi_match: {
            query: query,
            fields: %w[title^2 content],
          },
        },
      )
    end

    ids = result.fetch(:hits).fetch(:hits).map { |hit| hit.fetch(:_id) }

    activerecord_class_and_ids =
      ids.each_with_object({}) do |id, hash|
        klass, id = id.split("-")
        hash[klass] ||= []
        hash[klass] << id
      end

    instances = activerecord_class_and_ids.flat_map do |klass, ids|
      klass.constantize.where(id: ids)
    end

    instances.sort_by do |instance|
      ids.index(instance.elasticsearch_id)
    end
  end

  def self.connection_pool
    @connection_pool ||= ConnectionPool.new(size: (ENV["RAILS_MAX_THREADS"] || 5).to_i, timeout: 5) do
      Client.new
    end
  end

  class Client
    HttpError = Class.new(StandardError)

    REQUEST_METHOD_TO_CLASS = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      put: Net::HTTP::Put,
      delete: Net::HTTP::Delete,
    }.freeze

    def initialize
      @url = ENV["ELASTICSEARCH_URL"] || "http://localhost:9200"
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/docs-index_.html#docs-index-api-request
    def index(index, id, document)
      request(:put, "#{index}/_doc/#{id}", document)
    end

    # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/docs-delete.html#docs-delete-api-request
    def delete(index, id)
      request(:delete, "#{index}/_doc/#{id}")
    end

    # Search API reference:
    # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/search-search.html#search-search
    # Query body reference:
    # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/search-search.html#search-search-api-request-body
    def search(index, query)
      request(:get, "#{index}/_search", query)
    end

    def request(method, path, params = nil)
      uri = URI("#{@url}/#{path}")

      request = REQUEST_METHOD_TO_CLASS.fetch(method).new(uri)
      request.content_type = "application/json"
      request.body = params&.to_json

      if uri.userinfo
        username, password = uri.userinfo.split(":")
        request.basic_auth(username, password)
      end

      Rails.logger.debug "[Elasticsearch/request] #{request.method} #{request.uri} #{request.body}" if Rails.logger.debug?

      response = connection.request(request)

      Rails.logger.debug "[Elasticsearch/response] #{response.code}, body: #{response.body}" if Rails.logger.debug?

      raise HttpError, "status: #{response.code}, body: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body, symbolize_names: true)
    end

    private

    def connection
      @connection ||= begin
        uri = URI.parse(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http
      end
    end
  end
end
