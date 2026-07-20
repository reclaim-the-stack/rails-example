RSpec.describe "SearchController" do
  describe "GET /search" do
    it "renders results matching the query" do
      post = Post.create!(title: "Kubernetes", body: "Reclaim the stack")

      stub_request(:get, "http://localhost:9200/searchables/_search")
        .to_return(
          status: 200,
          body: { hits: { hits: [{ _id: "Post-#{post.id}" }] } }.to_json,
          headers: { "Content-Type" => "application/json" },
        )

      get "/search", params: { query: "kubernetes" }

      expect(response).to be_successful
      expect(response.body).to include("Kubernetes")
    end

    it "does not query Elasticsearch when the query is blank" do
      get "/search"

      expect(response).to be_successful
    end
  end
end
