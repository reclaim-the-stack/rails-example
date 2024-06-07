RSpec.describe CachedUrl do
  describe ".expire_by_tags" do
    before do

    end

    it "purges non expired urls at Cloudflare but deletes all of them from the DB" do
      all = CachedUrl.create! url: "https://host.com/posts", tags: %w[section:posts posts:all], expires_at: 1.hour.from_now
      id1 = CachedUrl.create! url: "https://host.com/posts/1", tags: %w[section:posts posts:1], expires_at: 10.minutes.from_now

      # Already expired
      CachedUrl.create! url: "https://host.com/posts/2", tags: %w[section:posts posts:2], expires_at: 5.minutes.ago

      # Not requested
      id3 = CachedUrl.create! url: "https://host.com/posts/3", tags: %w[section:posts posts:3], expires_at: 1.hour.from_now

      purge_request = stub_request(:post, "https://api.cloudflare.com/client/v4/zones/zone-id/purge_cache")
        .with(body: { files: [all.url, id1.url] }.to_json)

      CachedUrl.expire_by_tags(%w[posts:all posts:1 posts:2])

      expect(purge_request).to have_been_requested
      expect(CachedUrl.pluck(:url)).to eq [id3.url]
    end
  end
end