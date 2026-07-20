RSpec.describe "LinksController" do
  describe "GET /links" do
    it "returns a successful response" do
      Link.create!(url: "https://example.com")

      get "/links"

      expect(response).to be_successful
    end
  end

  describe "POST /links" do
    it "creates a link and redirects to the index" do
      expect {
        post "/links", params: { link: { url: "https://example.com" } }
      }.to change(Link, :count).by(1)

      expect(response).to redirect_to(links_path)
    end

    it "rejects an invalid URL" do
      expect {
        post "/links", params: { link: { url: "not a url" } }
      }.not_to change(Link, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
