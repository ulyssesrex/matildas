require 'rails_helper'

RSpec.describe "pages/home.html.erb", type: :view do
  before do
    view.define_singleton_method(:admin?) { false }
    allow(view).to receive(:admin?).and_return(false)
  end

  it "renders shows with venue details and Eastern Time formatting" do
    venue = Venue.new(name: "Union Hall", city: "Brooklyn", state: "NY")
    show = Show.new(
      date: Date.new(2026, 7, 10),
      time: "19:30",
      price: "$15",
      venue: venue
    )

    assign(:shows, [ show ])

    render template: "pages/home"

    expect(rendered).not_to include("<thead>")
    expect(rendered).not_to include("<th>Date</th>")
    expect(rendered).not_to include("<th>Time</th>")
    expect(rendered).not_to include("<th>Venue</th>")
    expect(rendered).not_to include("<th>Location</th>")
    expect(rendered).not_to include("<th>Price</th>")
    expect(rendered).to include("July 10, 2026")
    expect(rendered).to include("7:30 PM")
    expect(rendered).to include("Union Hall")
    expect(rendered).to include("Brooklyn, NY")
    expect(rendered).to include("$15")
  end

  it "links the venue and renders only artists as a prefixed comma-separated list" do
    venue = Venue.new(
      name: "Union Hall", city: "Brooklyn", state: "NY",
      map_url: "https://maps.example/union"
    )
    show = Show.new(date: Date.new(2026, 7, 10), time: "19:30", price: "$15", venue: venue)
    show.links = [
      Link.new(name: "Artist One", url: "https://example.com/one", artist: true),
      Link.new(name: "Tickets", url: "https://example.com/tickets", artist: false),
      Link.new(name: "Artist Two", url: "https://example.com/two", artist: true)
    ]

    assign(:shows, [ show ])
    render template: "pages/home"
    row = Nokogiri::HTML.fragment(rendered).css(".shows-table tr").first
    artists = row.at_css(".shows-table__artists")

    expect(row.at_css('a[href="https://maps.example/union"]')&.text).to eq("Union Hall")
    expect(artists.text.squish).to eq("w/ Artist One, Artist Two")
    expect(artists.css("a").map { |anchor| [ anchor.text, anchor["href"] ] }).to eq([
      [ "Artist One", "https://example.com/one" ],
      [ "Artist Two", "https://example.com/two" ]
    ])
    expect(row).not_to have_link("Tickets")
  end

  it "keeps an unlinked venue name and an empty final cell when no URLs exist" do
    venue = Venue.new(name: "Union Hall", city: "Brooklyn", state: "NY")
    show = Show.new(date: Date.new(2026, 7, 10), time: "19:30", price: "$15", venue: venue)

    assign(:shows, [ show ])
    render template: "pages/home"
    row = Nokogiri::HTML.fragment(rendered).css(".shows-table tr").first

    expect(row.text).to include("Union Hall")
    expect(row.css("a")).to be_empty
    expect(row.at_css(".shows-table__artists").text.strip).to be_empty
  end

  it "renders the two-panel show form for an admin" do
    allow(view).to receive(:admin?).and_return(true)
    assign(:shows, [])
    assign(:show_form, Admin::ShowForm.new)
    assign(:venues, [ Venue.new(id: 1, name: "Union Hall", city: "Brooklyn", state: "NY") ])
    assign(:links, [ Link.new(id: 1, name: "Tickets") ])

    render template: "pages/home"

    expect(rendered).to include('class="admin-show-form__panels"')
    expect(rendered).to include("Date", "Time", "Price", "Existing Venue")
    expect(rendered).to include("City", "State", "Map URL", "Name")
    expect(rendered).to include("Tickets")
    expect(rendered).to include("Show details and Artists")
    expect(rendered).to include("With artists", "Or Create An Artist", "Add another Artist")
    expect(rendered).not_to include("Existing Artists", "New Artists")
    expect(rendered).not_to include("Existing Links", "New Links", "Add another Link")
    expect(rendered).to include('data-controller="link-rows"')
    expect(rendered).to include('data-action="link-rows#add"')
    expect(rendered).to include('data-action="link-rows#remove"')
    expect(rendered).to include("Create Show")

    document = Nokogiri::HTML.fragment(rendered)
    artist_field = document.at_css('[data-controller="artist-select"]')
    artist_select = artist_field.at_css('select[name="admin_show_form[link_ids][]"]')

    search_input = artist_field.at_css('input[type="search"][data-artist-select-target="search"]')
    expect(search_input).to be_present
    expect(search_input["aria-label"]).to eq("Search artists")
    expect(artist_field.at_css('label[for="artist_search"]')).not_to be_present
    expect(artist_field.at_css('[data-action="input->artist-select#filter"]')).to be_present
    expect(artist_select).to have_attribute("multiple")
    expect(artist_select["data-artist-select-target"]).to eq("select")
    expect(artist_select.css("option").map(&:text)).to eq([ "Tickets" ])
    expect(artist_field.css('input[type="checkbox"][name="admin_show_form[link_ids][]"]')).to be_empty

    venue_field = document.at_css('[data-controller="artist-select"]:has(select[name="admin_show_form[venue_id]"])')
    venue_select = venue_field.at_css('select[name="admin_show_form[venue_id]"]')

    venue_search = venue_field.at_css('input[type="search"][data-artist-select-target="search"]')
    expect(venue_search).to be_present
    expect(venue_search["aria-label"]).to eq("Search venues")
    expect(venue_field.at_css('label[for="venue_search"]')).not_to be_present
    expect(venue_field.at_css('[data-action="input->artist-select#filter"]')).to be_present
    expect(venue_select).not_to have_attribute("multiple")
    expect(venue_select["data-artist-select-target"]).to eq("select")
    expect(venue_select.css("option").map(&:text)).to include("Union Hall (Brooklyn, NY)")
    expect(venue_select.at_css('option[value="1"]')&.text).to eq("Union Hall (Brooklyn, NY)")

    form = Nokogiri::HTML.fragment(rendered).at_css('[data-controller="show-cancellation"]')
    expect(form).to be_present
    expect(form.at_css('[data-show-cancellation-target="checkbox"]')).not_to have_attribute("checked")
    expect(form.at_css('[data-show-cancellation-target="ordinaryNotes"]')).not_to have_attribute("hidden")
    expect(form.at_css('[data-show-cancellation-target="cancellationNotes"]')).to have_attribute("hidden")
  end

  it "shows cancellation notes and preserves ordinary notes in a cancelled admin form" do
    allow(view).to receive(:admin?).and_return(true)
    assign(:shows, [])
    assign(:show_form, Admin::ShowForm.new(
      cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
    ))
    assign(:venues, [])
    assign(:links, [])

    render template: "pages/home"

    form = Nokogiri::HTML.fragment(rendered).at_css('[data-controller="show-cancellation"]')
    expect(form.at_css('[data-show-cancellation-target="checkbox"]')).to have_attribute("checked")
    expect(form.at_css('[data-show-cancellation-target="ordinaryNotes"]')).to have_attribute("hidden")
    expect(form.at_css('[data-show-cancellation-target="ordinaryNotes"] textarea').text.strip).to eq("Doors at 7")
    expect(form.at_css('[data-show-cancellation-target="cancellationNotes"]')).not_to have_attribute("hidden")
    expect(form.at_css('[data-show-cancellation-target="cancellationNotes"] textarea').text.strip).to eq("Venue closed")
  end

  it "does not render an Edit column for non-admins" do
    show = Show.create!(date: Date.new(2026, 7, 10), time: "19:30", price: "$15")
    assign(:shows, [ show ])

    render template: "pages/home"

    expect(Nokogiri::HTML.fragment(rendered).css(".shows-table__edit")).to be_empty
  end

  it "renders a separate Edit cell for each Show when admin" do
    allow(view).to receive(:admin?).and_return(true)
    show = Show.create!(date: Date.new(2026, 7, 10), time: "19:30", price: "$15")
    assign(:shows, [ show ])
    assign(:show_form, Admin::ShowForm.new)
    assign(:venues, [])
    assign(:links, [])

    render template: "pages/home"

    cell = Nokogiri::HTML.fragment(rendered).at_css(".shows-table__edit")
    expect(cell.at_css("a")["href"]).to eq(edit_admin_show_path(show))
    expect(cell.at_css("a").text).to eq("Edit")
  end

  it "renders TBD when a show has no time" do
    show = Show.new(date: Date.new(2026, 7, 10), time: nil, price: "$15")
    assign(:shows, [ show ])

    render template: "pages/home"

    row = Nokogiri::HTML.fragment(rendered).at_css(".shows-table tr")
    expect(row.css("td")[0].text).to include("July 10, 2026")
    expect(row.css("td")[1].text.strip).to eq("TBD")
  end

  it "renders ordinary notes for an active show" do
    show = Show.new(
      date: Date.new(2026, 7, 10), time: "19:30", price: "$15", notes: "Doors at 7"
    )
    assign(:shows, [ show ])

    render template: "pages/home"

    row = Nokogiri::HTML.fragment(rendered).at_css(".shows-table tr")
    expect(row.css("td")[1].text.strip).to eq("7:30 PM")
    expect(row.at_css(".shows-table__notes").text.strip).to eq("Doors at 7")
  end

  it "renders a cancelled show in red with cancellation time and notes" do
    show = Show.new(
      date: Date.new(2026, 7, 10), time: "19:30", price: "$15",
      cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
    )
    assign(:shows, [ show ])

    render template: "pages/home"

    row = Nokogiri::HTML.fragment(rendered).at_css(".shows-table tr")
    expect(row["class"]).to include("shows-table__row--cancelled")
    expect(row.css("td")[1].text.strip).to eq("SHOW CANCELLED")
    expect(row.at_css(".shows-table__notes").text.strip).to eq("Venue closed")
    expect(row.text).not_to include("Doors at 7")
  end
end
