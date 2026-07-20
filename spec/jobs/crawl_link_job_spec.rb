RSpec.describe CrawlLinkJob do
  it "updates the link with Open Graph data from the crawled page" do
    link = Link.create!(url: "https://example.com/article")

    html = <<~HTML
      <html>
        <head>
          <meta property="og:title" content="Example Article" />
          <meta property="og:description" content="An example description" />
          <meta property="og:image" content="https://example.com/image.png" />
        </head>
        <body></body>
      </html>
    HTML

    stub_request(:get, "https://example.com/article").to_return(status: 200, body: html)

    described_class.perform_now(link.id)

    expect(link.reload).to have_attributes(
      state: "success",
      title: "Example Article",
      description: "An example description",
      image_url: "https://example.com/image.png",
    )
  end

  it "marks the link as errored when the page cannot be fetched" do
    link = Link.create!(url: "https://example.com/nothing")

    stub_request(:get, "https://example.com/nothing").to_timeout

    described_class.perform_now(link.id)

    expect(link.reload.state).to eq("error")
  end
end
