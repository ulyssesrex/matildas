require 'rails_helper'

RSpec.describe "admin password routes", type: :routing do
  it "does not route password reset requests" do
    expect(get: "/admin/password/new").not_to be_routable
    expect(post: "/admin/password").not_to be_routable
    expect(get: "/admin/password/reset-token/edit").not_to be_routable
    expect(patch: "/admin/password/reset-token").not_to be_routable
  end
end
