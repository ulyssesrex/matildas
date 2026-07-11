class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    @shows = Show.unexpired.includes(:venue, :links).order(:time)
    return unless admin?

    @show_form = Admin::ShowForm.new
    @venues = Venue.order(:name, :city)
    @links = Link.order(:name)
  end
end
