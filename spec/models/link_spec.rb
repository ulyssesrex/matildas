require "rails_helper"

RSpec.describe Link do
  it "defaults to a non-artist" do
    expect(described_class.new).not_to be_artist
  end
end
