class AboutController < ApplicationController
  def index
    @page_title = 'About the Constellation'
  end

  def tos
    @page_title = 'Terms of Service'
  end

  def privacy
    @page_title = 'Privacy Policy'
  end
end
