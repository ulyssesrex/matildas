class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    @shows = Show.unexpired.includes(:venue, :links).order(:time)
  end
end
