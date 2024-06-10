class CachedUrl < ApplicationRecord
  scope :tagged_one_of, -> (tags) { where("tags && ARRAY[?]::varchar[]", tags) }

  def self.expire_by_tags(tags)
    transaction do
      cached_urls = tagged_one_of(tags)

      now = Time.now
      urls_to_purge = cached_urls.map { |cu| cu.url unless cu.expires_at < now }.compact

      Cloudflare.purge_by_urls(urls_to_purge)

      cached_urls.delete_all
    end
  end
end
