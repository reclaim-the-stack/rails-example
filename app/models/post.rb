class Post < ApplicationRecord
  include Elasticsearchable

  validates_presence_of :title
  validates_presence_of :body

  def elasticsearch_content
    body
  end
end
