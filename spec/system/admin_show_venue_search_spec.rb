require "rails_helper"

RSpec.describe "Admin show venue search", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1200, 900 ]

    User.create!(email_address: "admin@example.com", password: "password", admin: true)
    Venue.create!(name: "Alpha Hall", city: "Raleigh", state: "NC")
    Venue.create!(name: "Beta Club", city: "Durham", state: "NC")

    visit new_admin_session_path
    fill_in "Admin Email", with: "admin@example.com"
    fill_in "Password", with: "password"
    click_button "Secure Login"
  end

  it "filters venues by their display text while keeping the selection visible" do
    search_input = find('input[aria-label="Search venues"]')
    select "Alpha Hall (Raleigh, NC)", from: "Existing Venue"
    search_input.fill_in(with: "durham")

    alpha = find('#admin_show_form_venue_id option[value]', text: "Alpha Hall (Raleigh, NC)", visible: :all)
    beta = find('#admin_show_form_venue_id option[value]', text: "Beta Club (Durham, NC)", visible: :all)

    expect(alpha).to be_selected
    expect(page.evaluate_script("arguments[0].hidden", alpha.native)).to be(false)
    expect(page.evaluate_script("arguments[0].hidden", beta.native)).to be(false)

    search_input.fill_in(with: "missing")

    expect(page.evaluate_script("arguments[0].hidden", alpha.native)).to be(false)
    expect(page.evaluate_script("arguments[0].hidden", beta.native)).to be(true)

    search_input.fill_in(with: "")

    expect(page.evaluate_script("arguments[0].hidden", beta.native)).to be(false)
  end
end
