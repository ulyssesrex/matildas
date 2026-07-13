require "rails_helper"

RSpec.describe "Application stylesheet" do
  subject(:stylesheet) { Rails.root.join("app/assets/stylesheets/application.css").read }

  it "uses the body heading size for home section headings and navigation links" do
    expect(stylesheet).to match(/--body-heading-font-size:\s*1\.5rem;/)
    expect(stylesheet).to match(/\.home-section h2\s*\{[^}]*font-size:\s*var\(--body-heading-font-size\);/m)
    expect(stylesheet).to match(/\.site-nav__link\s*\{[^}]*font-size:\s*var\(--body-heading-font-size\);/m)
  end
end
