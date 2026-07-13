class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    @shows = Show.unexpired.includes(:venue, :artists).chronological
    return unless admin?

    @show_form = Admin::ShowForm.new
    @venues = Venue.order(:name, :city)
    @artists = Artist.order(:name)
  end
end
