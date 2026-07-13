require 'rails_helper'

RSpec.describe "Pages", type: :request do
  def sign_in(user)
    post admin_session_path, params: { email_address: user.email_address, password: "password" }
  end

  describe "GET /" do
    it "allows unauthenticated visitors" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "renders navigation links to each home page section" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<nav class="site-nav" aria-label="Primary navigation">')
      expect(response.body).to include('<a class="site-nav__link site-nav__brand" href="#top">THE MOON RINGERS</a>')
      expect(response.body).to match(
        %r{<a class="site-nav__link site-nav__brand" href="#top">THE MOON RINGERS</a>\s*<div class="site-nav__links">\s*<a class="site-nav__link" href="#music">Music</a>\s*<a class="site-nav__link" href="#shows">Shows</a>\s*<a class="site-nav__link" href="#misc">Misc</a>\s*</div>}
      )
      expect(response.body).to include('<a class="site-nav__link" href="#music">Music</a>')
      expect(response.body).to include('<a class="site-nav__link" href="#shows">Shows</a>')
      expect(response.body).to include('<a class="site-nav__link" href="#misc">Misc</a>')
      expect(response.body).to include('<main id="top"')
      expect(response.body).to include('<section id="music"')
      expect(response.body).to include('<section id="shows"')
      expect(response.body).to include('<section id="misc"')
    end

    it "does not show the creation form to unauthenticated visitors" do
      get root_path

      expect(response.body).not_to include("Create Show")
    end

    it "shows the creation form to admins" do
      admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
      sign_in(admin)

      get root_path

      expect(response.body).to include("Create Show")
    end

    it "does not show the creation form to a signed-in non-admin" do
      user = User.create!(email_address: "former-admin@example.com", password: "password", admin: true)
      sign_in(user)
      user.update!(admin: false)

      get root_path

      expect(response.body).not_to include("Create Show")
    end
  end
end
