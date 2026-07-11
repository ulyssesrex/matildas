require "rails_helper"

RSpec.describe Admin::ShowForm do
  subject(:form) { described_class.new(attributes) }

  let(:attributes) do
    { date: "2026-07-10", time: "19:30", price: "$15" }
  end

  it "requires date, time, and price" do
    form = described_class.new

    expect(form).not_to be_valid
    expect(form.errors).to include(:date, :time, :price)
  end

  it "persists daylight-saving Eastern input as UTC" do
    expect { form.save }.to change(Show, :count).by(1)

    expect(form.show.time).to eq(Time.utc(2026, 7, 10, 23, 30))
  end

  it "persists standard-time Eastern input as UTC" do
    form = described_class.new(attributes.merge(date: "2026-12-10"))

    expect(form.save).to be(true)
    expect(form.show.time).to eq(Time.utc(2026, 12, 11, 0, 30))
  end

  it "rejects invalid dates and times" do
    form = described_class.new(attributes.merge(date: "2026-02-30", time: "25:00"))

    expect(form).not_to be_valid
    expect(form.errors).to include(:date, :time)
  end

  it "associates an existing venue" do
    venue = Venue.create!(name: "Union Hall", city: "Brooklyn", state: "NY", map_url: "https://maps.example/union")
    form = described_class.new(attributes.merge(venue_id: venue.id))

    expect(form.save).to be(true)
    expect(form.show.venue).to eq(venue)
  end

  it "creates and associates a complete new venue" do
    form = described_class.new(attributes.merge(new_venue: {
      name: "The Sinclair", city: "Cambridge", state: "MA", map_url: "https://maps.example/sinclair"
    }))

    expect { form.save }.to change(Venue, :count).by(1)
    expect(form.show.venue).to have_attributes(name: "The Sinclair", city: "Cambridge", state: "MA")
  end

  it "rejects choosing and creating a venue together" do
    venue = Venue.create!(name: "Union Hall")
    form = described_class.new(attributes.merge(
      venue_id: venue.id,
      new_venue: { name: "The Sinclair", city: "Cambridge", state: "MA", map_url: "https://maps.example/sinclair" }
    ))

    expect(form).not_to be_valid
    expect(form.errors[:venue]).to include("choose an existing venue or create a new venue, not both")
  end

  it "requires every new venue field once venue entry starts" do
    form = described_class.new(attributes.merge(new_venue: { name: "The Sinclair" }))

    expect(form).not_to be_valid
    expect(form.errors).to include(:new_venue_city, :new_venue_state, :new_venue_map_url)
  end

  it "rejects an unknown venue id" do
    form = described_class.new(attributes.merge(venue_id: "999999"))

    expect(form).not_to be_valid
    expect(form.errors[:venue_id]).to include("is invalid")
  end

  it "combines unique existing links with multiple new links" do
    existing = Link.create!(name: "Venue", url: "https://example.com/venue")
    form = described_class.new(attributes.merge(
      link_ids: ["", existing.id.to_s, existing.id.to_s],
      new_links: {
        "0" => { name: "Tickets", url: "https://example.com/tickets" },
        "1" => { name: "Info", url: "https://example.com/info" },
        "2" => { name: "", url: "" }
      }
    ))

    expect { form.save }.to change(Link, :count).by(2)
    expect(form.show.links.pluck(:name)).to contain_exactly("Venue", "Tickets", "Info")
  end

  it "requires both fields in a started new link row" do
    form = described_class.new(attributes.merge(new_links: { "0" => { name: "Tickets", url: "" } }))

    expect(form).not_to be_valid
    expect(form.errors[:new_links]).to include("row 1 URL can't be blank")
  end

  it "rejects unknown existing link ids" do
    form = described_class.new(attributes.merge(link_ids: ["999999"]))

    expect(form).not_to be_valid
    expect(form.errors[:link_ids]).to include("contain an invalid Link")
  end

  it "rolls back every record when persistence fails" do
    allow(Link).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Link.new))
    form = described_class.new(attributes.merge(
      new_venue: { name: "The Sinclair", city: "Cambridge", state: "MA", map_url: "https://maps.example/sinclair" },
      new_links: { "0" => { name: "Tickets", url: "https://example.com/tickets" } }
    ))

    expect { form.save }.not_to change { [Show.count, Venue.count, Link.count] }
    expect(form.errors[:base]).to be_present
  end
end
