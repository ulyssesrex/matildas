require "rails_helper"

RSpec.describe "Admin show artist search", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1200, 900 ]

    User.create!(email_address: "admin@example.com", password: "password", admin: true)
    Artist.create!(name: "Alpha Artist", url: "https://example.com/alpha")
    Artist.create!(name: "Beta Band", url: "https://example.com/beta")

    visit new_admin_session_path
    fill_in "Admin Email", with: "admin@example.com"
    fill_in "Password", with: "password"
    click_button "Secure Login"
  end

  it "filters unselected artists while keeping selections visible" do
    search_input = find('input[aria-label="Search artists"]')
    select "Alpha Artist", from: "With artists"
    search_input.fill_in(with: "beta")

    alpha = find('#admin_show_form_artist_ids option[value]', text: "Alpha Artist", visible: :all)
    beta = find('#admin_show_form_artist_ids option[value]', text: "Beta Band", visible: :all)

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
