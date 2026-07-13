# Artist Model Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove Links from the application and database, replacing them with required-name-and-URL Artists associated directly with Shows.

**Architecture:** Introduce an `Artist` Active Record model and a direct HABTM `Show` association through `artists_shows`. A destructive migration discards the pre-production Link tables, while the existing show form transaction creates and associates Artists through Artist-specific parameters and errors.

**Tech Stack:** Rails 8.1, Active Record migrations, Active Model form object, ERB, Stimulus, RSpec, Capybara/Selenium

---

## File map

- Create `db/migrate/20260713120000_replace_links_with_artists.rb`: destructively replace both Link tables with Artist tables.
- Create `app/models/artist.rb`: define Artist validation and Show association.
- Delete `app/models/link.rb`: remove the Link model.
- Modify `app/models/show.rb`: replace `links` with `artists`.
- Create `spec/models/artist_spec.rb`: cover required fields, association, and final schema.
- Delete `spec/models/link_spec.rb`: remove obsolete Link behavior.
- Modify `app/forms/admin/show_form.rb`: accept, validate, create, and associate Artists.
- Modify `spec/forms/admin/show_form_spec.rb`: cover Artist create/edit/rollback behavior.
- Modify `app/controllers/admin/shows_controller.rb`: permit Artist parameters and load Artist choices.
- Modify `app/controllers/pages_controller.rb`: eager-load and expose Artists.
- Modify `app/views/pages/home.html.erb`: render Artists and pass Artist choices to the form partial.
- Modify `app/views/pages/_admin_show_form.html.erb`: use Artist locals, parameters, errors, and row hooks.
- Modify `app/views/admin/shows/edit.html.erb`: pass Artists to the form partial.
- Modify `spec/requests/admin_shows_spec.rb`: exercise Artist parameters and edit selections.
- Modify `spec/views/pages/home.html.erb_spec.rb`: cover Artist-only public and admin markup.
- Create `app/javascript/controllers/artist_rows_controller.js`: retain dynamic row behavior under Artist terminology.
- Delete `app/javascript/controllers/link_rows_controller.js`: eliminate Link terminology.
- Modify `spec/system/admin_show_artist_search_spec.rb`: use Artist records and selectors.
- Create `spec/system/admin_show_artist_rows_spec.rb`: cover adding and removing new Artist rows.
- Modify `db/schema.rb`: generated final schema after migration.

### Task 1: Replace the persistence model and schema

**Files:**
- Create: `spec/models/artist_spec.rb`
- Delete: `spec/models/link_spec.rb`
- Create: `db/migrate/20260713120000_replace_links_with_artists.rb`
- Create: `app/models/artist.rb`
- Delete: `app/models/link.rb`
- Modify: `app/models/show.rb`
- Modify: `db/schema.rb`

- [ ] **Step 1: Write the failing Artist model and schema spec**

Create `spec/models/artist_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Artist, type: :model do
  it "requires a name and URL" do
    artist = described_class.new

    expect(artist).not_to be_valid
    expect(artist.errors).to include(:name, :url)
  end

  it "associates with shows in both directions" do
    artist = described_class.create!(name: "Alpha Artist", url: "https://example.com/alpha")
    show = Show.create!(date: Date.new(2026, 7, 10), price: "$15", artists: [ artist ])

    expect(show.artists).to contain_exactly(artist)
    expect(artist.shows).to contain_exactly(show)
  end

  it "uses Artist tables without legacy Link tables" do
    connection = ActiveRecord::Base.connection

    expect(connection.data_source_exists?(:artists)).to be(true)
    expect(connection.data_source_exists?(:artists_shows)).to be(true)
    expect(connection.data_source_exists?(:links)).to be(false)
    expect(connection.data_source_exists?(:links_shows)).to be(false)
  end
end
```

- [ ] **Step 2: Run the spec to verify it fails for the missing model**

Run: `.local/bin/bundle exec rspec spec/models/artist_spec.rb`

Expected: FAIL with an uninitialized `Artist` constant.

- [ ] **Step 3: Add the destructive migration**

Create `db/migrate/20260713120000_replace_links_with_artists.rb`:

```ruby
class ReplaceLinksWithArtists < ActiveRecord::Migration[8.1]
  def up
    drop_join_table :shows, :links
    drop_table :links

    create_table :artists do |t|
      t.string :name, null: false
      t.string :url, null: false

      t.timestamps
    end

    create_join_table :artists, :shows do |t|
      t.index [ :artist_id, :show_id ], unique: true
      t.index [ :show_id, :artist_id ], unique: true
    end
  end

  def down
    drop_join_table :artists, :shows
    drop_table :artists

    create_table :links do |t|
      t.string :name
      t.string :url
      t.boolean :artist, default: false, null: false

      t.timestamps
    end

    create_join_table :shows, :links do |t|
      t.index [ :show_id, :link_id ]
      t.index [ :link_id, :show_id ]
    end
  end
end
```

- [ ] **Step 4: Add the Artist model and replace the Show association**

Create `app/models/artist.rb`:

```ruby
class Artist < ApplicationRecord
  has_and_belongs_to_many :shows

  validates :name, :url, presence: true
end
```

Change `app/models/show.rb` to use:

```ruby
has_and_belongs_to_many :artists
```

Delete `app/models/link.rb` and `spec/models/link_spec.rb`.

- [ ] **Step 5: Migrate development and test databases**

Run: `.local/bin/bundle exec rails db:migrate`

Expected: exit 0; `db/schema.rb` has version `2026_07_13_120000`, Artist tables with non-null fields and unique composite indexes, and no Link tables.

Run: `RAILS_ENV=test .local/bin/bundle exec rails db:migrate`

Expected: exit 0.

- [ ] **Step 6: Run the model specs to verify green**

Run: `.local/bin/bundle exec rspec spec/models/artist_spec.rb spec/models/show_spec.rb`

Expected: all examples pass.

- [ ] **Step 7: Commit the persistence replacement**

```bash
git add app/models db/migrate/20260713120000_replace_links_with_artists.rb db/schema.rb spec/models
git commit -m "Replace links with artists"
```

### Task 2: Convert the Show form object to Artists

**Files:**
- Modify: `spec/forms/admin/show_form_spec.rb`
- Modify: `app/forms/admin/show_form.rb`

- [ ] **Step 1: Rewrite the association examples around the Artist API**

In `spec/forms/admin/show_form_spec.rb`, replace every `Link`, `link_ids`, `new_links`, `links`, and Link-named fixture with the corresponding `Artist`, `artist_ids`, `new_artists`, `artists`, and Artist name. The core create example must be:

```ruby
it "combines unique existing artists with multiple new artists" do
  existing = Artist.create!(name: "Venue", url: "https://example.com/venue")
  form = described_class.new(attributes.merge(
    artist_ids: [ "", existing.id.to_s, existing.id.to_s ],
    new_artists: {
      "0" => { name: "Tickets", url: "https://example.com/tickets" },
      "1" => { name: "Info", url: "https://example.com/info" },
      "2" => { name: "", url: "" }
    }
  ))

  expect { form.save }.to change(Artist, :count).by(2)
  expect(form.show.artists.pluck(:name)).to contain_exactly("Venue", "Tickets", "Info")
end
```

The invalid-ID assertion must expect:

```ruby
expect(form.errors[:artist_ids]).to include("contain an invalid Artist")
```

The incomplete-row assertion must use `new_artists` and expect the error on `:new_artists`. Rollback examples must stub `Artist.create!`, count `Artist`, and assert the original `show.artists` association survives.

- [ ] **Step 2: Run the form spec to verify Artist API failures**

Run: `.local/bin/bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: FAIL because `Admin::ShowForm` does not accept `artist_ids` or `new_artists` and still calls Link APIs.

- [ ] **Step 3: Replace Link state and behavior in the form object**

In `app/forms/admin/show_form.rb`:

```ruby
attr_accessor :artist_ids, :new_venue, :new_artists
```

Initialize empty values with:

```ruby
self.artist_ids ||= []
self.new_venue ||= {}
self.new_artists ||= {}
```

Register Artist validators:

```ruby
validate :existing_artist_ids_are_valid
validate :new_artist_rows_are_complete
```

Within the transaction, replace the association and create submitted artists:

```ruby
@show.artists = existing_artists
normalized_new_artists.each { |artist_attributes| @show.artists << Artist.create!(artist_attributes) }
```

Populate edit state with:

```ruby
artist_ids: show.artist_ids.map(&:to_s),
```

Expose submitted rows and private normalization under Artist names:

```ruby
def submitted_new_artists
  rows = normalized_hash(new_artists).values.map { |row| normalized_hash(row).slice("name", "url") }
  rows.presence || [ { "name" => "", "url" => "" } ]
end

def existing_artist_ids_are_valid
  return if normalized_artist_ids.empty?

  errors.add(:artist_ids, "contain an invalid Artist") unless existing_artists.length == normalized_artist_ids.length
end

def new_artist_rows_are_complete
  submitted_new_artists.each_with_index do |row, index|
    next if row.values.all?(&:blank?)

    errors.add(:new_artists, "row #{index + 1} Name can't be blank") if row["name"].blank?
    errors.add(:new_artists, "row #{index + 1} URL can't be blank") if row["url"].blank?
  end
end

def existing_artists
  @existing_artists ||= Artist.where(id: normalized_artist_ids).to_a
end

def normalized_artist_ids
  @normalized_artist_ids ||= Array(artist_ids).reject(&:blank?).map(&:to_s).uniq
end

def normalized_new_artists
  submitted_new_artists.filter_map do |row|
    row.symbolize_keys if row.values.any?(&:present?)
  end
end
```

Remove all Link-named form methods and state.

- [ ] **Step 4: Run the form spec to verify green**

Run: `.local/bin/bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: all examples pass.

- [ ] **Step 5: Commit the form conversion**

```bash
git add app/forms/admin/show_form.rb spec/forms/admin/show_form_spec.rb
git commit -m "Associate artists through show form"
```

### Task 3: Convert controllers and views to Artist data

**Files:**
- Modify: `spec/requests/admin_shows_spec.rb`
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/controllers/admin/shows_controller.rb`
- Modify: `app/controllers/pages_controller.rb`
- Modify: `app/views/pages/home.html.erb`
- Modify: `app/views/pages/_admin_show_form.html.erb`
- Modify: `app/views/admin/shows/edit.html.erb`

- [ ] **Step 1: Convert request and view specs to Artist terminology**

Replace request fixtures and expectations with `Artist`, `artist_ids`, `new_artists`, and `show.artists`. The edit selector must be:

```ruby
artist_select = document.at_css('select[name="admin_show_form[artist_ids][]"][multiple]')
expect(artist_select.at_css("option[value='#{artist.id}'][selected]")&.text).to eq("Tickets")
```

In the admin view spec, assign:

```ruby
assign(:artists, [ Artist.new(id: 1, name: "Tickets", url: "https://example.com/tickets") ])
```

and select:

```ruby
artist_select = artist_field.at_css('select[name="admin_show_form[artist_ids][]"]')
expect(artist_field.css('input[type="checkbox"][name="admin_show_form[artist_ids][]"]')).to be_empty
```

The public rendering example must associate only Artists:

```ruby
show.artists = [
  Artist.new(name: "Artist One", url: "https://example.com/one"),
  Artist.new(name: "Artist Two", url: "https://example.com/two")
]
```

All admin render setups must assign `:artists`, never `:links`. Assert `data-controller="artist-rows"`, `artist-rows#add`, and `artist-rows#remove`.

- [ ] **Step 2: Run request and view specs to verify failures**

Run: `.local/bin/bundle exec rspec spec/requests/admin_shows_spec.rb spec/views/pages/home.html.erb_spec.rb`

Expected: FAIL because controllers do not permit Artist parameters and templates still expect Link locals and associations.

- [ ] **Step 3: Convert controller loading and strong parameters**

In `app/controllers/admin/shows_controller.rb`, eager-load `:artists`, permit:

```ruby
artist_ids: [],
new_artists: [ :name, :url ]
```

and prepare:

```ruby
@artists = Artist.order(:name)
```

Both home-loading paths must use:

```ruby
Show.unexpired.includes(:venue, :artists).chronological
```

Make the same eager-loading and `@artists` change in `app/controllers/pages_controller.rb`.

- [ ] **Step 4: Convert the templates**

Pass `artists: @artists` from both `app/views/pages/home.html.erb` and `app/views/admin/shows/edit.html.erb`.

In the public show row, render directly from the association:

```erb
<% if show.artists.any? %>
  w/
  <% show.artists.each_with_index do |artist, index| %><%= ", " unless index.zero? %><%= link_to artist.name, artist.url %><% end %>
<% end %>
```

In `app/views/pages/_admin_show_form.html.erb`, use `selected_artist_ids`, the `artists` local, `admin_show_form_artist_ids`, and the parameter `admin_show_form[artist_ids][]`. Render row values from `form.submitted_new_artists` with names under `admin_show_form[new_artists]`. Rename all row CSS/data hooks to `new-artist-*`, `artist-rows`, and `data-artist-row`, and render errors for `:artist_ids` and `:new_artists`.

- [ ] **Step 5: Run request and view specs to verify green**

Run: `.local/bin/bundle exec rspec spec/requests/admin_shows_spec.rb spec/views/pages/home.html.erb_spec.rb`

Expected: all examples pass.

- [ ] **Step 6: Commit the web-layer conversion**

```bash
git add app/controllers app/views spec/requests/admin_shows_spec.rb spec/views/pages/home.html.erb_spec.rb
git commit -m "Use artists in show administration"
```

### Task 4: Rename dynamic row behavior and preserve artist search

**Files:**
- Modify: `spec/system/admin_show_artist_search_spec.rb`
- Create: `spec/system/admin_show_artist_rows_spec.rb`
- Create: `app/javascript/controllers/artist_rows_controller.js`
- Delete: `app/javascript/controllers/link_rows_controller.js`

- [ ] **Step 1: Convert search fixtures and write a failing dynamic-row system test**

Create the fixtures with `Artist.create!` and locate options with:

```ruby
alpha = find('#admin_show_form_artist_ids option[value]', text: "Alpha Artist", visible: :all)
beta = find('#admin_show_form_artist_ids option[value]', text: "Beta Band", visible: :all)
```

Create `spec/system/admin_show_artist_rows_spec.rb`:

```ruby
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
```

- [ ] **Step 2: Run the dynamic-row spec to verify the missing controller fails**

Run: `.local/bin/bundle exec rspec spec/system/admin_show_artist_rows_spec.rb`

Expected: FAIL because clicking “Add another Artist” leaves the page with one row while the `artist-rows` controller is missing.

- [ ] **Step 3: Replace the Link row controller**

Create `app/javascript/controllers/artist_rows_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "rows"]

  connect() {
    this.nextIndex = Date.now()
  }

  add() {
    const row = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", this.nextIndex++)
    this.rowsTarget.insertAdjacentHTML("beforeend", row)
  }

  remove(event) {
    event.currentTarget.closest("[data-artist-row]").remove()
  }
}
```

Delete `app/javascript/controllers/link_rows_controller.js`. Stimulus eager loading registers `artist_rows_controller.js` automatically as `artist-rows`.

- [ ] **Step 4: Run both Artist system specs to verify green**

Run: `.local/bin/bundle exec rspec spec/system/admin_show_artist_search_spec.rb spec/system/admin_show_artist_rows_spec.rb`

Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit the JavaScript and system-test conversion**

```bash
git add app/javascript/controllers spec/system/admin_show_artist_search_spec.rb spec/system/admin_show_artist_rows_spec.rb
git commit -m "Remove link row terminology"
```

### Task 5: Verify complete Link removal

**Files:**
- No source changes expected; any discovered defect returns to the relevant earlier task before completion.

- [ ] **Step 1: Search runtime code and current specs for obsolete concepts**

Run: `rg -n "\\bLink\\b|\\blinks\\b|link_ids|new_links|link-rows|link_rows|data-link-row" app spec db/schema.rb`

Expected: no matches. Ordinary English such as Rails comments about generated navigation links is outside these paths or unrelated; old migration files are intentionally excluded.

- [ ] **Step 2: Run the complete test suite**

Run: `.local/bin/bundle exec rspec`

Expected: all examples pass with 0 failures.

- [ ] **Step 3: Run RuboCop**

Run: `.local/bin/bundle exec rubocop`

Expected: no offenses.

- [ ] **Step 4: Validate migration reversibility and final forward schema**

Run: `.local/bin/bundle exec rails db:rollback STEP=1`

Expected: exit 0; the migration recreates `links` and `links_shows`.

Run: `.local/bin/bundle exec rails db:migrate`

Expected: exit 0; `artists` and `artists_shows` are restored and Link tables are absent.

Run: `.local/bin/bundle exec rspec spec/models/artist_spec.rb`

Expected: 3 examples, 0 failures against the restored forward schema.

- [ ] **Step 5: Review the final diff**

Run: `git diff --check && git status --short && git diff --stat`

Expected: no whitespace errors, no uncommitted changes, and only in-scope commits added to `main`.
