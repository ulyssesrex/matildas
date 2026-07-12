# Searchable Show Artists Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the admin show form's artist checkboxes with a dependency-free searchable native multiselect and align the artist-creation wording with the venue section.

**Architecture:** The shared ERB partial will render a standard multiple select that continues submitting `admin_show_form[link_ids][]`. A focused Stimulus controller will progressively enhance it by hiding unselected options that do not match a case-insensitive search, while selected options remain visible.

**Tech Stack:** Rails 8 ERB form helpers, Stimulus 3, importmap, RSpec view/request/system specs, Nokogiri, Selenium with headless Chrome

---

## File structure

- Modify `spec/views/pages/home.html.erb_spec.rb` to specify the new-form labels, native multiselect contract, Stimulus hooks, and absence of the old artist checkboxes.
- Modify `spec/requests/admin_shows_spec.rb` to specify that an edit form renders associated artists as selected multiselect options.
- Create `spec/system/admin_show_artist_search_spec.rb` to exercise filtering and selection in a JavaScript-capable browser.
- Modify `app/views/pages/_admin_show_form.html.erb` to render the searchable multiselect and revised creation divider in the shared new/edit form.
- Create `app/javascript/controllers/artist_select_controller.js` to filter the multiselect's options without changing their selected state.

### Task 1: Specify the new and edit form markup

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb:74-100`
- Modify: `spec/requests/admin_shows_spec.rb:104-119`

- [ ] **Step 1: Write the failing new-form view expectations**

Replace the artist-label assertions in `renders the two-panel show form for an admin` and add structural expectations after rendering:

```ruby
expect(rendered).to include("With artists", "Or Create An Artist", "Add another Artist")
expect(rendered).not_to include("Existing Artists", "New Artists")

document = Nokogiri::HTML.fragment(rendered)
artist_field = document.at_css('[data-controller="artist-select"]')
artist_select = artist_field.at_css('select[name="admin_show_form[link_ids][]"]')

expect(artist_field.at_css('input[type="search"][data-artist-select-target="search"]')).to be_present
expect(artist_field.at_css('[data-action="input->artist-select#filter"]')).to be_present
expect(artist_select).to have_attribute("multiple")
expect(artist_select["data-artist-select-target"]).to eq("select")
expect(artist_select.css("option").map(&:text)).to eq([ "Tickets" ])
expect(artist_field.css('input[type="checkbox"][name="admin_show_form[link_ids][]"]')).to be_empty
```

Keep the existing assertions for the panels, cancellation controller, link-row controller, and submit button.

- [ ] **Step 2: Write the failing edit-form selection expectation**

In `renders a prefilled edit form for an admin`, replace the checkbox expectation:

```ruby
expect(document.at_css("input[value='#{link.id}'][checked]")).to be_present
```

with:

```ruby
artist_select = document.at_css('select[name="admin_show_form[link_ids][]"][multiple]')
expect(artist_select.at_css("option[value='#{link.id}'][selected]")&.text).to eq("Tickets")
```

- [ ] **Step 3: Run the focused specs to verify RED**

Run:

```bash
.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb spec/requests/admin_shows_spec.rb
```

Expected: FAIL because the form still renders `Existing Artists`, `New Artists`, and artist checkboxes, and the edit form has no multiple select.

- [ ] **Step 4: Commit the failing specifications**

```bash
git add spec/views/pages/home.html.erb_spec.rb spec/requests/admin_shows_spec.rb
git commit -m "Test searchable artist multiselect markup"
```

### Task 2: Render the searchable native multiselect

**Files:**
- Modify: `app/views/pages/_admin_show_form.html.erb:69-105`
- Test: `spec/views/pages/home.html.erb_spec.rb`
- Test: `spec/requests/admin_shows_spec.rb`

- [ ] **Step 1: Replace the existing-artist checkbox block**

Replace lines 69-85 of the shared partial with:

```erb
<div class="form-field" data-controller="artist-select">
  <% if links.any? %>
    <%= label_tag :admin_show_form_link_ids, "With artists", class: "form-label" %>
    <%= label_tag :artist_search, "Search artists" %>
    <%= search_field_tag :artist_search, nil,
          autocomplete: "off",
          data: {
            action: "input->artist-select#filter",
            artist_select_target: "search"
          } %>
    <%= select_tag "admin_show_form[link_ids][]",
          options_from_collection_for_select(links, :id, :name, selected_link_ids),
          id: "admin_show_form_link_ids",
          multiple: true,
          size: [ [ links.size, 4 ].max, 8 ].min,
          data: { artist_select_target: "select" } %>
  <% else %>
    <span class="form-label">With artists</span>
    <p class="form-hint">No existing Artists.</p>
  <% end %>
  <% form.errors.full_messages_for(:link_ids).each do |message| %><p class="field-error"><%= message %></p><% end %>
</div>
```

This keeps the existing parameter name and uses `selected_link_ids`, so both edit forms and invalid redisplays preserve selections.

- [ ] **Step 2: Replace the artist-creation label**

In the `data-controller="link-rows"` block, replace:

```erb
<span class="form-label">New Artists</span>
```

with:

```erb
<p class="form-divider"><span>Or Create An Artist</span></p>
```

- [ ] **Step 3: Run the focused specs to verify GREEN**

Run:

```bash
.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb spec/requests/admin_shows_spec.rb
```

Expected: PASS.

- [ ] **Step 4: Commit the form markup**

```bash
git add app/views/pages/_admin_show_form.html.erb
git commit -m "Render artist multiselect in show form"
```

### Task 3: Add dependency-free artist filtering

**Files:**
- Create: `app/javascript/controllers/artist_select_controller.js`
- Create: `spec/system/admin_show_artist_search_spec.rb`

- [ ] **Step 1: Write a failing browser spec for filtering**

Create `spec/system/admin_show_artist_search_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Admin show artist search", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1200, 900 ]

    User.create!(email_address: "admin@example.com", password: "password", admin: true)
    Link.create!(name: "Alpha Artist", url: "https://example.com/alpha", artist: true)
    Link.create!(name: "Beta Band", url: "https://example.com/beta", artist: true)

    visit new_admin_session_path
    fill_in "Admin Email", with: "admin@example.com"
    fill_in "Password", with: "password"
    click_button "Secure Login"
  end

  it "filters unselected artists while keeping selections visible" do
    select "Alpha Artist", from: "With artists"
    fill_in "Search artists", with: "beta"

    alpha = find('#admin_show_form_link_ids option[value]', text: "Alpha Artist", visible: :all)
    beta = find('#admin_show_form_link_ids option[value]', text: "Beta Band", visible: :all)

    expect(alpha).to be_selected
    expect(page.evaluate_script("arguments[0].hidden", alpha.native)).to be(false)
    expect(page.evaluate_script("arguments[0].hidden", beta.native)).to be(false)

    fill_in "Search artists", with: "missing"

    expect(page.evaluate_script("arguments[0].hidden", alpha.native)).to be(false)
    expect(page.evaluate_script("arguments[0].hidden", beta.native)).to be(true)

    fill_in "Search artists", with: ""

    expect(page.evaluate_script("arguments[0].hidden", beta.native)).to be(false)
  end
end
```

- [ ] **Step 2: Run the system spec to verify RED**

Run:

```bash
.local/bin/bundle exec rspec spec/system/admin_show_artist_search_spec.rb
```

Expected: FAIL because `artist_select_controller.js` does not exist and entering a query does not hide the unmatched option.

- [ ] **Step 3: Create the focused Stimulus controller**

Create `app/javascript/controllers/artist_select_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "select"]

  filter() {
    const query = this.searchTarget.value.trim().toLowerCase()

    for (const option of this.selectTarget.options) {
      const matches = option.text.toLowerCase().includes(query)
      option.hidden = !option.selected && !matches
    }
  }
}
```

Stimulus is already eager-loaded from `app/javascript/controllers`, so no manual registration or import-map change is required.

- [ ] **Step 4: Run the system spec to verify GREEN**

Run:

```bash
.local/bin/bundle exec rspec spec/system/admin_show_artist_search_spec.rb
```

Expected: PASS.

- [ ] **Step 5: Run all automated checks**

Run:

```bash
.local/bin/bundle exec rspec
.local/bin/bundle exec rubocop
```

Expected: both commands exit successfully with no failures or offenses.

- [ ] **Step 6: Verify filtering manually in both forms**

Start Rails with `.local/bin/bundle exec rails server`, sign in as an administrator, and verify on both the new and edit show forms:

1. `With artists` labels a visible multiple select.
2. Typing a partial artist name, regardless of case, hides unmatched unselected options.
3. A selected artist stays visible when the query no longer matches it.
4. Clearing the query restores all options.
5. Submitting multiple selections associates every selected artist with the show.
6. The creation divider reads `Or Create An Artist`.

- [ ] **Step 7: Commit the filtering controller and browser spec**

```bash
git add app/javascript/controllers/artist_select_controller.js spec/system/admin_show_artist_search_spec.rb
git commit -m "Add searchable artist filtering"
```
