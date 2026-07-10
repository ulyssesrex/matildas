require 'rails_helper'

RSpec.describe "pages/home.html.erb", type: :view do
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
end
