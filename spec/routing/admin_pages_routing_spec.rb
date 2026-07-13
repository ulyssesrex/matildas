require "rails_helper"

RSpec.describe "admin page routes", type: :routing do
  it "routes the admin root directly to the admin login page" do
    expect(get: "/admin").to route_to(
      controller: "admin/sessions",
      action: "new"
    )
  end
end
