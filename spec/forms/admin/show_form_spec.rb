require "rails_helper"

RSpec.describe Admin::ShowForm do
  subject(:form) { described_class.new(attributes) }

  let(:attributes) do
    { date: "2026-07-10", time: "19:30", price: "$15" }
  end

  it "requires date and price" do
    form = described_class.new

    expect(form).not_to be_valid
    expect(form.errors).to include(:date, :price)
    expect(form.errors).not_to include(:time)
  end

  it "persists date and local clock time independently" do
    expect { form.save }.to change(Show, :count).by(1)

    expect(form.show.date).to eq(Date.new(2026, 7, 10))
    expect(form.show.time.strftime("%H:%M")).to eq("19:30")
  end

  it "saves a required date with no time" do
    form = described_class.new(attributes.merge(time: ""))

    expect(form.save).to be(true)
    expect(form.show).to have_attributes(date: Date.new(2026, 7, 10), time: nil)
  end

  it "persists cancellation state and both kinds of notes" do
    form = described_class.new(attributes.merge(
      cancelled: "1", notes: "Doors at 7", cancellation_notes: "Venue closed"
    ))

    expect(form.save).to be(true)
    expect(form.show).to have_attributes(
      cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
    )
  end

  it "allows a cancelled show without cancellation notes" do
    form = described_class.new(attributes.merge(cancelled: "1", cancellation_notes: ""))

    expect(form.save).to be(true)
    expect(form.show).to have_attributes(cancelled: true, cancellation_notes: "")
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

  it "combines unique existing artists with multiple new artists" do
    existing = Artist.create!(name: "Venue", url: "https://example.com/venue")
    form = described_class.new(attributes.merge(
      artist_ids: [ "", existing.id.to_s, existing.id.to_s ],
      new_artists: {
        "0" => { name: "Tickets", url: "https://example.com/tickets" },
        "1" => { name: "Info", url: "https://example.com/info" },
        "2" => { name: "", url: "" }
      }
    ))

    expect { form.save }.to change(Artist, :count).by(2)
    expect(form.show.artists.pluck(:name)).to contain_exactly("Venue", "Tickets", "Info")
  end

  it "requires both fields in a started new artist row" do
    form = described_class.new(attributes.merge(new_artists: { "0" => { name: "Tickets", url: "" } }))

    expect(form).not_to be_valid
    expect(form.errors[:new_artists]).to include("row 1 URL can't be blank")
  end

  it "rejects unknown existing artist ids" do
    form = described_class.new(attributes.merge(artist_ids: [ "999999" ]))

    expect(form).not_to be_valid
    expect(form.errors[:artist_ids]).to include("contain an invalid Artist")
  end

  it "rolls back every record when persistence fails" do
    allow(Artist).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Artist.new))
    form = described_class.new(attributes.merge(
      new_venue: { name: "The Sinclair", city: "Cambridge", state: "MA", map_url: "https://maps.example/sinclair" },
      new_artists: { "0" => { name: "Tickets", url: "https://example.com/tickets" } }
    ))

    expect { form.save }.not_to change { [ Show.count, Venue.count, Artist.count ] }
    expect(form.errors[:base]).to be_present
  end

  describe "editing" do
    let!(:venue) do
      Venue.create!(
        name: "Union Hall", city: "Brooklyn", state: "NY",
        map_url: "https://maps.example/union"
      )
    end
    let!(:replacement_venue) do
      Venue.create!(
        name: "The Sinclair", city: "Cambridge", state: "MA",
        map_url: "https://maps.example/sinclair"
      )
    end
    let!(:existing_artist) { Artist.create!(name: "Venue", url: "https://example.com/venue") }
    let!(:replacement_artist) { Artist.create!(name: "Details", url: "https://example.com/details") }
    let!(:show) do
      Show.create!(date: Date.new(2026, 7, 10), time: "19:30", price: "$15", venue: venue).tap do |record|
        record.artists = [ existing_artist ]
      end
    end

    it "prefills attributes and associations from the show" do
      form = described_class.new(show: show)

      expect(form).to have_attributes(
        date: "2026-07-10", time: "19:30", price: "$15",
        venue_id: venue.id.to_s, artist_ids: [ existing_artist.id.to_s ]
      )
    end

    it "updates fields and replaces existing associations" do
      form = described_class.new(
        show: show,
        date: "2026-08-12", time: "20:15", price: "$20",
        venue_id: replacement_venue.id.to_s,
        artist_ids: [ replacement_artist.id.to_s ]
      )

      expect(form.save).to be(true)
      expect(show.reload).to have_attributes(
        date: Date.new(2026, 8, 12), price: "$20", venue: replacement_venue
      )
      expect(show.time.strftime("%H:%M")).to eq("20:15")
      expect(show.artists).to contain_exactly(replacement_artist)
    end

    it "creates a new venue and artist while editing" do
      form = described_class.new(
        show: show,
        date: "2026-07-10", time: "19:30", price: "$18",
        new_venue: {
          name: "Elsewhere", city: "Brooklyn", state: "NY",
          map_url: "https://maps.example/elsewhere"
        },
        new_artists: {
          "0" => { name: "Tickets", url: "https://example.com/tickets" }
        }
      )

      expect { form.save }.to change(Venue, :count).by(1).and change(Artist, :count).by(1)
      expect(show.reload.venue.name).to eq("Elsewhere")
      expect(show.artists.pluck(:name)).to contain_exactly("Tickets")
    end

    it "rolls back show updates when an associated record fails" do
      allow(Artist).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Artist.new))
      form = described_class.new(
        show: show,
        date: "2026-08-12", time: "20:15", price: "$20",
        cancelled: "1", notes: "Updated notes", cancellation_notes: "Venue closed",
        new_artists: {
          "0" => { name: "Tickets", url: "https://example.com/tickets" }
        }
      )

      expect(form.save).to be(false)
      expect(show.reload).to have_attributes(
        date: Date.new(2026, 7, 10), price: "$15", venue: venue,
        cancelled: false, notes: nil, cancellation_notes: nil
      )
      expect(show.time.strftime("%H:%M")).to eq("19:30")
      expect(show.artists).to contain_exactly(existing_artist)
    end

    it "prefills and preserves both notes through cancellation changes" do
      show.update!(notes: "Doors at 7")

      cancel_form = described_class.new(
        show: show, date: "2026-07-10", time: "19:30", price: "$15",
        cancelled: "1", notes: "Doors at 7", cancellation_notes: "Venue closed"
      )
      expect(cancel_form.save).to be(true)

      prefilled = described_class.new(show: show.reload)
      expect(prefilled).to have_attributes(
        cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
      )

      active_form = described_class.new(
        show: show, date: "2026-07-10", time: "19:30", price: "$15",
        cancelled: "0", notes: "Doors at 7", cancellation_notes: "Venue closed"
      )
      expect(active_form.save).to be(true)
      expect(show.reload).to have_attributes(
        cancelled: false, notes: "Doors at 7", cancellation_notes: "Venue closed"
      )
    end

    it "prefills a TBD show with a blank time" do
      show.update!(time: nil)

      expect(described_class.new(show: show)).to have_attributes(date: "2026-07-10", time: nil)
    end
  end
end
