class Post < ApplicationRecord
  include Searchable

  validates_presence_of :title
  validates_presence_of :body

  private

  def searchable_content
    body
  end
end
