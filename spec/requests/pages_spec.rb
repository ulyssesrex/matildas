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

    it "uses the logo asset as the favicon and Apple touch icon" do
      get root_path

      document = Nokogiri::HTML(response.body)
      logo_asset_path = ActionController::Base.helpers.asset_path("logo.png")
      favicon = document.at_css('head link[rel="icon"][type="image/png"]')
      apple_touch_icon = document.at_css('head link[rel="apple-touch-icon"]')

      expect(favicon["href"]).to eq(logo_asset_path)
      expect(apple_touch_icon["href"]).to eq(logo_asset_path)
      expect(document.css('head link[rel="icon"]').length).to eq(1)
    end

    it "renders the band photo immediately above the Music section" do
      get root_path

      document = Nokogiri::HTML(response.body)
      image = document.at_css("main#top > img.home-page__band-photo")
      music_section = document.at_css("main#top > section#music")

      expect(image).to be_present
      expect(image["src"]).to eq(ActionController::Base.helpers.asset_path("band_pic.jpg"))
      expect(image["alt"]).to eq("The Moon Ringers band")
      expect(music_section.previous_element).to eq(image)
    end

    it "renders the Bandcamp players below Music in album order" do
      get root_path

      document = Nokogiri::HTML(response.body)
      music_section = document.at_css("main#top > section#music")
      heading = music_section.at_css("h2")
      player_container = music_section.at_css(".bandcamp-players")
      players = player_container.element_children.select do |element|
        element.name == "iframe" && element["class"].split.include?("bandcamp-embed")
      end

      expect(heading.text).to eq("Music")
      expect(heading.next_element).to eq(player_container)
      expect(players.map { |player| player["src"] }).to eq([
        "https://bandcamp.com/EmbeddedPlayer/album=3770867506/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/",
        "https://bandcamp.com/EmbeddedPlayer/album=1816368499/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/",
        "https://bandcamp.com/EmbeddedPlayer/album=3392802803/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/",
        "https://bandcamp.com/EmbeddedPlayer/album=3200630352/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/"
      ])
      expect(players.map { |player| player["title"] }).to eq([
        "Bandcamp player for Magic Mirror EP by The Matildas",
        "Bandcamp player for Dark Corners EP by The Matildas",
        "Bandcamp player for Ample Shortage (Demo) by The Matildas",
        "Bandcamp player for Noise That Works (Demo) by The Matildas"
      ])
      expect(players.map { |player| player["loading"] }).to all(eq("lazy"))
      expect(response.body).to include(
        'href="https://matildas.bandcamp.com/album/magic-mirror-ep"',
        'href="https://matildas.bandcamp.com/album/dark-corners-ep"',
        'href="https://matildas.bandcamp.com/album/ample-shortage-demo"',
        'href="https://matildas.bandcamp.com/album/noise-that-works-demo"'
      )
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
