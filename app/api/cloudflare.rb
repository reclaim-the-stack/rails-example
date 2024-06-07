module Cloudflare
  BASE_URL = "https://api.cloudflare.com/client/v4".freeze

  # https://developers.cloudflare.com/api/operations/zone-purge#purge-cached-content-by-tag-host-or-prefix
  #
  # Rate-limiting: Cache-Tag, host and prefix purging each have a rate limit
  # of 30,000 purge API calls in every 24 hour period. You may purge up to
  # 30 tags, hosts, or prefixes in one API call. This rate limit can be
  # raised for customers who need to purge at higher volume.
  #
  # Provide tags as an Array of Strings, eg: ["mnd-assets-id-xxx", ...] or a single String
  def self.purge_by_tags(tags, zone_id: ENV.fetch("CLOUDFLARE_ZONE_ID"))
    tags = Array.wrap(tags)

    post("zones/#{zone_id}/purge_cache", tags:)
  end

  # https://developers.cloudflare.com/api/operations/zone-purge#purge-cached-content-by-url
  def self.purge_by_urls(urls, zone_id: ENV.fetch("CLOUDFLARE_ZONE_ID"))
    urls = Array.wrap(urls)

    post("zones/#{zone_id}/purge_cache", files: urls)
  end

  # https://developers.cloudflare.com/api/operations/zone-purge#purge-all-cached-content
  def self.purge_everything(zone_id: ENV.fetch("CLOUDFLARE_ZONE_ID"))
    post("zones/#{zone_id}/purge_cache", purge_everything: true)
  end

  %w[get post delete patch].each do |verb|
    define_singleton_method(verb) do |path, params = {}|
      request(verb.upcase, path, params)
    end
  end

  def self.request(verb, path, params)
    HTTPX.send(
      verb.downcase,
      "#{BASE_URL}/#{path}",
      headers: {
        "Authorization" => "Bearer #{ENV.fetch('CLOUDFLARE_API_TOKEN')}",
        "Accept" => "application/json",
      },
      json: params,
    ).raise_for_status
  end
end
