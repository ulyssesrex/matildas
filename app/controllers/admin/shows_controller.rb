class Admin::ShowsController < ApplicationController
  before_action :require_admin

  def edit
    @show = Show.includes(:venue, :links).find(params[:id])
    @show_form = Admin::ShowForm.new(show: @show)
    prepare_choices
  end

  def create
    @show_form = Admin::ShowForm.new(show_form_params)

    if @show_form.save
      redirect_to root_path(anchor: "shows"), notice: "Show created."
    else
      prepare_home
      render "pages/home", status: :unprocessable_content
    end
  end

  def update
    @show = Show.includes(:venue, :links).find(params[:id])
    @show_form = Admin::ShowForm.new(show_form_params.to_h.merge(show: @show))

    if @show_form.save
      redirect_to root_path, notice: "Show updated."
    else
      prepare_choices
      render :edit, status: :unprocessable_content
    end
  end

  private

    def show_form_params
      params.require(:admin_show_form).permit(
        :date, :time, :price, :venue_id,
        link_ids: [],
        new_venue: [ :name, :city, :state, :map_url ],
        new_links: [ :name, :url ]
      )
    end

    def prepare_home
      @shows = Show.unexpired.includes(:venue, :links).chronological
      prepare_choices
    end

    def prepare_choices
      @venues = Venue.order(:name, :city)
      @links = Link.order(:name)
    end
end
