require 'rails_helper'

RSpec.describe "Pages", type: :request do
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
      expect(response.body).to include('<a class="site-nav__link" href="#music">Music</a>')
      expect(response.body).to include('<a class="site-nav__link" href="#shows">Shows</a>')
      expect(response.body).to include('<a class="site-nav__link" href="#misc">Misc</a>')
      expect(response.body).to include('<main id="top"')
      expect(response.body).to include('<section id="music"')
      expect(response.body).to include('<section id="shows"')
      expect(response.body).to include('<section id="misc"')
    end
  end
end
