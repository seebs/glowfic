require Rails.root.join('lib', 'post_scraper')

class ScrapePostJob < ApplicationJob
  queue_as :low

  def perform(url, board_id, section_id, status, threaded, importer_id)
    Resque.logger.debug "Starting scrape for #{url}"
    scraper = PostScraper.new(url, board_id, section_id, status, threaded)
    scraped_post = scraper.scrape!
    Message.send_site_message(importer_id, 'Post import succeeded', "Your post was successfully imported! #{self.class.view_post(scraped_post.id)}")
  end

  def self.notify_exception(exception, url, board_id, section_id, status, threaded, importer_id)
    Resque.logger.warn "Failed to import #{url}: #{exception.message}"
    if User.find_by_id(importer_id)
      message = "The url <a href='#{url}'>#{url}</a> could not be successfully scraped. "
      message += exception.message if exception.is_a?(UnrecognizedUsernameError)
      message += "Your post was already imported! #{view_post(exception.post_id)}" if exception.is_a?(AlreadyImportedError)
      Message.send_site_message(importer_id, 'Post import failed', message)
    end
    super
  end

  def self.view_post(post_id)
    url = Rails.application.routes.url_helpers.post_url(post_id, host: ENV['DOMAIN_NAME'] || 'localhost:3000', protocol: 'https')
    "<a href='#{url}'>View it here</a>."
  end
end
