RSpec.describe "PostsController" do
  describe "GET /posts" do
    it "returns a successful response" do
      Post.create!(title: "Title", body: "Body")

      get "/posts"

      expect(response).to be_successful
    end
  end
end
