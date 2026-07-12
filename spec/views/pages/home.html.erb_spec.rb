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

  it "links a venue with a map URL and renders all Show links in the final cell" do
    venue = Venue.new(
      name: "Union Hall", city: "Brooklyn", state: "NY",
      map_url: "https://maps.example/union"
    )
    show = Show.new(date: Date.new(2026, 7, 10), time: "19:30", price: "$15", venue: venue)
    show.links = [
      Link.new(name: "Tickets", url: "https://example.com/tickets"),
      Link.new(name: "Details", url: "https://example.com/details")
    ]

    assign(:shows, [ show ])
    render template: "pages/home"
    row = Nokogiri::HTML.fragment(rendered).css(".shows-table tr").first

    expect(row.at_css('a[href="https://maps.example/union"]')&.text).to eq("Union Hall")
    expect(row.css("td").last.css("a").map { |anchor| [ anchor.text, anchor["href"] ] }).to eq([
      [ "Tickets", "https://example.com/tickets" ],
      [ "Details", "https://example.com/details" ]
    ])
  end

  it "keeps an unlinked venue name and an empty final cell when no URLs exist" do
    venue = Venue.new(name: "Union Hall", city: "Brooklyn", state: "NY")
    show = Show.new(date: Date.new(2026, 7, 10), time: "19:30", price: "$15", venue: venue)

    assign(:shows, [ show ])
    render template: "pages/home"
    row = Nokogiri::HTML.fragment(rendered).css(".shows-table tr").first

    expect(row.text).to include("Union Hall")
    expect(row.css("a")).to be_empty
    expect(row.css("td").last.text.strip).to be_empty
  end

  it "renders the two-panel show form for an admin" do
    allow(view).to receive(:admin?).and_return(true)
    assign(:shows, [])
    assign(:show_form, Admin::ShowForm.new)
    assign(:venues, [ Venue.new(id: 1, name: "Union Hall", city: "Brooklyn", state: "NY") ])
    assign(:links, [ Link.new(id: 1, name: "Tickets") ])

    render template: "pages/home"

    expect(rendered).to include('class="admin-show-form__panels"')
    expect(rendered).to include("Date", "Time", "Price", "Existing venue")
    expect(rendered).to include("City", "State", "Map URL", "Name")
    expect(rendered).to include("Tickets")
    expect(rendered).to include('data-controller="link-rows"')
    expect(rendered).to include('data-action="link-rows#add"')
    expect(rendered).to include('data-action="link-rows#remove"')
    expect(rendered).to include("Create Show")

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
end
