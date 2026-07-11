require "rails_helper"

RSpec.describe "Admin shows", type: :request do
  def sign_in(user)
    post admin_session_path, params: {
      email_address: user.email_address,
      password: "password"
    }
  end

  describe "POST /admin/shows" do
    it "redirects unauthenticated visitors to the admin login page" do
      post admin_shows_path, params: { admin_show_form: {} }

      expect(response).to redirect_to(new_admin_session_path)
    end

    it "forbids an authenticated user who is not an admin" do
      user = User.create!(email_address: "former-admin@example.com", password: "password", admin: true)
      sign_in(user)
      user.update!(admin: false)

      post admin_shows_path, params: { admin_show_form: attributes_for_request }

      expect(response).to have_http_status(:forbidden)
    end

    it "creates a show with existing and new associated records for an admin" do
      admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
      venue = Venue.create!(name: "Union Hall", city: "Brooklyn", state: "NY", map_url: "https://maps.example/union")
      existing_link = Link.create!(name: "Venue", url: "https://example.com/venue")
      sign_in(admin)

      expect {
        post admin_shows_path, params: {
          admin_show_form: {
            date: "2026-07-10", time: "19:30", price: "$15", venue_id: venue.id,
            link_ids: [existing_link.id],
            new_links: {
              "0" => { name: "Tickets", url: "https://example.com/tickets" },
              "1" => { name: "Info", url: "https://example.com/info" }
            }
          }
        }
      }.to change(Show, :count).by(1).and change(Link, :count).by(2)

      expect(response).to redirect_to(root_path(anchor: "shows"))
      expect(Show.last).to have_attributes(venue: venue, price: "$15", time: Time.utc(2026, 7, 10, 23, 30))
      expect(Show.last.links.pluck(:name)).to contain_exactly("Venue", "Tickets", "Info")
    end

    it "renders the home page with errors and entered values when invalid" do
      admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
      sign_in(admin)

      expect {
        post admin_shows_path, params: {
          admin_show_form: { date: "2026-07-10", time: "19:30", price: "" }
        }
      }.not_to change(Show, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Price can&#39;t be blank")
      expect(response.body).to include("2026-07-10")
    end
  end

  def attributes_for_request
    { date: "2026-07-10", time: "19:30", price: "$15" }
  end
end
