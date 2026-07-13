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
      existing_artist = Artist.create!(name: "Venue", url: "https://example.com/venue")
      sign_in(admin)

      expect {
        post admin_shows_path, params: {
          admin_show_form: {
            date: "2026-07-10", time: "19:30", price: "$15", venue_id: venue.id,
            cancelled: "1", notes: "Doors at 7", cancellation_notes: "Venue closed",
            artist_ids: [ existing_artist.id ],
            new_artists: {
              "0" => { name: "Tickets", url: "https://example.com/tickets" },
              "1" => { name: "Info", url: "https://example.com/info" }
            }
          }
        }
      }.to change(Show, :count).by(1).and change(Artist, :count).by(2)

      expect(response).to redirect_to(root_path(anchor: "shows"))
      expect(Show.last).to have_attributes(
        venue: venue, price: "$15", date: Date.new(2026, 7, 10),
        cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
      )
      expect(Show.last.time.strftime("%H:%M")).to eq("19:30")
      expect(Show.last.artists.pluck(:name)).to contain_exactly("Venue", "Tickets", "Info")
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

    it "creates a show with a TBD time" do
      admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
      sign_in(admin)

      post admin_shows_path, params: {
        admin_show_form: { date: "2026-07-10", time: "", price: "$15" }
      }

      expect(response).to redirect_to(root_path(anchor: "shows"))
      expect(Show.last).to have_attributes(date: Date.new(2026, 7, 10), time: nil)
    end
  end

  describe "GET /admin/shows/:id/edit" do
    let!(:show) { Show.create!(date: Date.new(2026, 7, 10), time: "19:30", price: "$15") }

    it "redirects unauthenticated visitors to the admin login page" do
      get edit_admin_show_path(show)

      expect(response).to redirect_to(new_admin_session_path)
    end

    it "forbids an authenticated user who is not an admin" do
      user = User.create!(email_address: "former-admin@example.com", password: "password", admin: true)
      sign_in(user)
      user.update!(admin: false)

      get edit_admin_show_path(show)

      expect(response).to have_http_status(:forbidden)
    end

    it "renders a prefilled edit form for an admin" do
      admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
      venue = Venue.create!(name: "Union Hall")
      artist = Artist.create!(name: "Tickets", url: "https://example.com/tickets")
      show.update!(venue: venue, artists: [ artist ])
      sign_in(admin)

      get edit_admin_show_path(show)

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      expect(response.body).to include("Edit Show", "2026-07-10", "19:30", "$15")
      expect(response.body).to include('name="_method" value="patch"')
      venue_select = document.at_css('select[name="admin_show_form[venue_id]"]')
      expect(venue_select.at_css("option[value='#{venue.id}'][selected]")&.text).to eq("Union Hall")
      artist_select = document.at_css('select[name="admin_show_form[artist_ids][]"][multiple]')
      expect(artist_select.at_css("option[value='#{artist.id}'][selected]")&.text).to eq("Tickets")
    end
  end

  describe "PATCH /admin/shows/:id" do
    let!(:show) { Show.create!(date: Date.new(2026, 7, 10), time: "19:30", price: "$15") }

    it "redirects unauthenticated visitors to the admin login page" do
      patch admin_show_path(show), params: { admin_show_form: attributes_for_request }

      expect(response).to redirect_to(new_admin_session_path)
    end

    it "forbids an authenticated user who is not an admin" do
      user = User.create!(email_address: "former-admin@example.com", password: "password", admin: true)
      sign_in(user)
      user.update!(admin: false)

      patch admin_show_path(show), params: { admin_show_form: attributes_for_request }

      expect(response).to have_http_status(:forbidden)
    end

    it "updates a show with new associated records and redirects home" do
      admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
      sign_in(admin)

      expect {
        patch admin_show_path(show), params: {
          admin_show_form: {
            date: "2026-08-12", time: "20:15", price: "$20",
            cancelled: "1", notes: "Doors at 7", cancellation_notes: "Venue closed",
            new_venue: {
              name: "Elsewhere", city: "Brooklyn", state: "NY",
              map_url: "https://maps.example/elsewhere"
            },
            new_artists: {
              "0" => { name: "Tickets", url: "https://example.com/tickets" }
            }
          }
        }
      }.to change(Venue, :count).by(1).and change(Artist, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(show.reload).to have_attributes(
        date: Date.new(2026, 8, 12), price: "$20", venue: Venue.last,
        cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
      )
      expect(show.time.strftime("%H:%M")).to eq("20:15")
      expect(show.artists.pluck(:name)).to contain_exactly("Tickets")
    end

    it "renders the edit page with submitted values when invalid" do
      admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
      venue = Venue.create!(name: "Union Hall")
      artist = Artist.create!(name: "Tickets", url: "https://example.com/tickets")
      show.update!(venue: venue, artists: [ artist ])
      sign_in(admin)

      patch admin_show_path(show), params: {
        admin_show_form: { date: "2026-08-12", time: "20:15", price: "" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Price can&#39;t be blank", "2026-08-12")
      expect(show.reload).to have_attributes(price: "$15", venue: venue)
      expect(show.artists).to contain_exactly(artist)
    end

    it "updates a show to have a TBD time" do
      admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
      sign_in(admin)

      patch admin_show_path(show), params: {
        admin_show_form: { date: "2026-08-12", time: "", price: "$20" }
      }

      expect(response).to redirect_to(root_path)
      expect(show.reload).to have_attributes(date: Date.new(2026, 8, 12), time: nil, price: "$20")
    end
  end

  def attributes_for_request
    { date: "2026-07-10", time: "19:30", price: "$15" }
  end
end
