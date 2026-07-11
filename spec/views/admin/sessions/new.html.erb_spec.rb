require 'rails_helper'

RSpec.describe "admin/sessions/new.html.erb", type: :view do
  it "does not render a password reset link" do
    render template: "admin/sessions/new"

    expect(rendered).not_to include("Forgot password?")
    expect(rendered).not_to include("password/new")
  end

  it "renders monochrome-compatible feedback without inline colors" do
    flash[:alert] = "Invalid credentials"
    flash[:notice] = "Signed out"

    render template: "admin/sessions/new"

    fragment = Nokogiri::HTML.fragment(rendered)
    messages = fragment.css(".flash")

    expect(messages.map(&:text)).to contain_exactly("Invalid credentials", "Signed out")
    expect(messages.map { |message| message["class"] }).to contain_exactly(
      "flash flash--alert",
      "flash flash--notice"
    )
    expect(rendered).not_to include("style=")
  end
end
