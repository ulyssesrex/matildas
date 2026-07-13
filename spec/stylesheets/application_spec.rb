require "rails_helper"

RSpec.describe "Application stylesheet" do
  subject(:stylesheet) { Rails.root.join("app/assets/stylesheets/application.css").read }

  it "uses the body heading size for home section headings and navigation links" do
    expect(stylesheet).to match(/--body-heading-font-size:\s*1\.5rem;/)
    expect(stylesheet).to match(/\.home-section h2\s*\{[^}]*font-size:\s*var\(--body-heading-font-size\);/m)
    expect(stylesheet).to match(/\.site-nav__link\s*\{[^}]*font-size:\s*var\(--body-heading-font-size\);/m)
  end

  it "preserves editable text casing while keeping selections and actions uppercase" do
    expect(stylesheet).to match(
      /input,\s*textarea\s*\{[^}]*text-transform:\s*none;/m
    )
    expect(stylesheet).not_to match(
      /\.form-field input\[type="date"\],[^{]*\{[^}]*text-transform:\s*uppercase;/m
    )
    expect(stylesheet).not_to match(
      /select[^{]*\{[^}]*text-transform:\s*none;/m
    )
    expect(stylesheet).to match(
      /\.form-button,\s*input\[type="submit"\]\s*\{[^}]*text-transform:\s*uppercase;/m
    )
  end

  it "draws a full-height separator before the navigation link group" do
    expect(stylesheet).to match(
      /\.site-nav__links\s*\{[^}]*border-left:\s*1px solid var\(--color-white\);/m
    )
  end

  it "uses a full-width separator and accurate scroll offset for the stacked navigation" do
    expect(stylesheet).to match(
      /@media \(max-width: 38rem\)\s*\{.*?:root\s*\{[^}]*--site-nav-height:\s*calc\(5\.5rem \+ 2px\);/m
    )
    expect(stylesheet).to match(
      /@media \(max-width: 38rem\)\s*\{.*?\.site-nav__links\s*\{[^}]*border-left:\s*0;[^}]*border-top:\s*1px solid var\(--color-white\);/m
    )
  end
end
