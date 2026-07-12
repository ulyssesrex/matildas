require "rails_helper"

RSpec.describe "Show", type: :model do
  describe "unexpired scope" do
    it "uses the show date, including when time is absent" do
      freeze_time do
        expired_show = Show.create!(date: 15.days.ago.to_date, price: "$15")
        boundary_show = Show.create!(date: 14.days.ago.to_date, price: "$15")
        future_tbd_show = Show.create!(date: 1.month.from_now.to_date, time: nil, price: "$15")

        expect(Show.unexpired).to contain_exactly(
          boundary_show,
          future_tbd_show,
        )
        expect(Show.unexpired).not_to include(expired_show)
      end
    end
  end

  describe "chronological scope" do
    it "orders by date and puts known times before TBD times" do
      tbd = Show.create!(date: Date.new(2026, 7, 10), time: nil, price: "$15")
      late = Show.create!(date: Date.new(2026, 7, 10), time: "20:00", price: "$15")
      early = Show.create!(date: Date.new(2026, 7, 10), time: "19:00", price: "$15")
      next_day = Show.create!(date: Date.new(2026, 7, 11), time: "18:00", price: "$15")

      expect(Show.chronological).to eq([early, late, tbd, next_day])
    end
  end
end
