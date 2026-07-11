require 'rails_helper'

RSpec.describe "pages/home.html.erb", type: :view do
  before do
    allow(view).to receive(:admin?).and_return(false)
  end

  it "renders shows with venue details and Eastern Time formatting" do
    venue = Venue.new(name: "Union Hall", city: "Brooklyn", state: "NY")
    show = Show.new(
      time: Time.utc(2026, 7, 10, 23, 30),
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
    show = Show.new(time: Time.utc(2026, 7, 10, 23, 30), price: "$15", venue: venue)
    show.links = [
      Link.new(name: "Tickets", url: "https://example.com/tickets"),
      Link.new(name: "Details", url: "https://example.com/details")
    ]

    assign(:shows, [show])
    render template: "pages/home"
    row = Nokogiri::HTML.fragment(rendered).css(".shows-table tr").first

    expect(row.at_css('a[href="https://maps.example/union"]')&.text).to eq("Union Hall")
    expect(row.css("td").last.css("a").map { |anchor| [anchor.text, anchor["href"]] }).to eq([
      ["Tickets", "https://example.com/tickets"],
      ["Details", "https://example.com/details"]
    ])
  end

  it "keeps an unlinked venue name and an empty final cell when no URLs exist" do
    venue = Venue.new(name: "Union Hall", city: "Brooklyn", state: "NY")
    show = Show.new(time: Time.utc(2026, 7, 10, 23, 30), price: "$15", venue: venue)

    assign(:shows, [show])
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
    assign(:venues, [Venue.new(id: 1, name: "Union Hall", city: "Brooklyn", state: "NY")])
    assign(:links, [Link.new(id: 1, name: "Tickets")])

    render template: "pages/home"

    expect(rendered).to include('class="admin-show-form__panels"')
    expect(rendered).to include("Date", "Time", "Price", "Existing venue")
    expect(rendered).to include("City", "State", "Map URL", "Name")
    expect(rendered).to include("Tickets")
    expect(rendered).to include('data-controller="link-rows"')
    expect(rendered).to include('data-action="link-rows#add"')
    expect(rendered).to include('data-action="link-rows#remove"')
    expect(rendered).to include("Create Show")
  end
end
