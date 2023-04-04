class CrawlLinkJob < ApplicationJob
  def perform(link_id)
    link = Link.find_by_id(link_id)
    return unless link

    og = OpenGraph.new(link.url)

    if og.description
      link.update!(
        state: "success",
        title: og.title,
        description: og.description,
        image_url: og.images.first,
      )
    else
      link.update!(state: "error")
    end
  end
end
