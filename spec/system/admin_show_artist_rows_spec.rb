require "rails_helper"

RSpec.describe "Admin show artist rows", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1200, 900 ]

    User.create!(email_address: "admin@example.com", password: "password", admin: true)
    visit new_admin_session_path
    fill_in "Admin Email", with: "admin@example.com"
    fill_in "Password", with: "password"
    click_button "Secure Login"
  end

  it "adds and removes new Artist rows" do
    expect(page).to have_css("[data-artist-row]", count: 1)

    click_button "Add another Artist"
    expect(page).to have_css("[data-artist-row]", count: 2)

    all("[data-artist-row]").last.click_button("Remove")
    expect(page).to have_css("[data-artist-row]", count: 1)
  end
end
