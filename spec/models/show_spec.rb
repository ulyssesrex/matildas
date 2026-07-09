require "rails_helper"

RSpec.describe "Show", type: :model do
  describe "unexpired scope" do
    it "returns shows that are newer than two weeks old" do
      freeze_time do
        expired_show = Show.create(time: 2.weeks.ago)
        unexpired_show = Show.create(time: 1.day.ago)
        present_show = Show.create(time: Time.now)
        future_show = Show.create(time: 1.month.from_now)

        expect(Show.unexpired).to contain_exactly(
          unexpired_show,
          present_show,
          future_show,
        )
      end
    end
  end
end

