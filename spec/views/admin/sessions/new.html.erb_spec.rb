require 'rails_helper'

RSpec.describe "admin/sessions/new.html.erb", type: :view do
  it "does not render a password reset link" do
    render template: "admin/sessions/new"

    expect(rendered).not_to include("Forgot password?")
    expect(rendered).not_to include("password/new")
  end
end
