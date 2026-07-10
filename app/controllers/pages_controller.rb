class PagesController < ApplicationController
  def home
    @shows = Show.unexpired.includes(:venue, :links).order(:time)
  end
end
