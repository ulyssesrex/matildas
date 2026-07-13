require "rails_helper"

RSpec.describe Artist, type: :model do
  it "requires a name and URL" do
    artist = described_class.new

    expect(artist).not_to be_valid
    expect(artist.errors).to include(:name, :url)
  end

  it "associates with shows in both directions" do
    artist = described_class.create!(name: "Alpha Artist", url: "https://example.com/alpha")
    show = Show.create!(date: Date.new(2026, 7, 10), price: "$15", artists: [ artist ])

    expect(show.artists).to contain_exactly(artist)
    expect(artist.shows).to contain_exactly(show)
  end

  it "uses Artist tables without legacy Link tables" do
    connection = ActiveRecord::Base.connection

    expect(connection.data_source_exists?(:artists)).to be(true)
    expect(connection.data_source_exists?(:artists_shows)).to be(true)
    expect(connection.data_source_exists?(:links)).to be(false)
    expect(connection.data_source_exists?(:links_shows)).to be(false)
  end
end
