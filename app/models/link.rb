class Link < ApplicationRecord
  validates_presence_of :url
  validate :validate_format_of_url
  validates_inclusion_of :state, in: %w[pending success error]

  after_create :enqueue_crawl_job
  after_update_commit -> { broadcast_replace_later_to "links", target: "link_#{id}" }

  private

  def enqueue_crawl_job
    CrawlLinkJob.perform_later(id)
  end

  def validate_format_of_url
    uri = URI(url)
    errors.add(:url, :invalid) unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    errors.add(:url, :invalid)
  end
end
