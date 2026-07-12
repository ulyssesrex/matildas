# Show Artists Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Classify links as artists, create artist links from the admin Show form, and render only those artists in the public Shows table as a linked `w/` list.

**Architecture:** Keep the existing `Link` model and HABTM association, adding a database-backed boolean classification with a safe false default. The form owns classification of newly created links, while the public view filters associated records at render time and leaves legacy non-artist links untouched.

**Tech Stack:** Rails 8.1, Active Record migrations, ERB, RSpec, Nokogiri

---

## File map

- Create `db/migrate/20260712130000_add_artist_to_links.rb`: add the non-null boolean classification.
- Create `spec/models/link_spec.rb`: document the default classification exposed by `Link`.
- Modify `db/schema.rb`: generated schema state after migration.
- Modify `app/forms/admin/show_form.rb`: force new links created by the Show form to be artists.
- Modify `spec/forms/admin/show_form_spec.rb`: cover classification during create and edit flows.
- Modify `app/views/pages/_admin_show_form.html.erb`: present link creation and selection as Artist fields.
- Modify `spec/views/pages/home.html.erb_spec.rb`: cover form terminology and public Artists-cell output.
- Modify `app/views/pages/home.html.erb`: filter artists and render the `w/` list.

### Task 1: Add the Link artist classification

**Files:**
- Create: `spec/models/link_spec.rb`
- Create: `db/migrate/20260712130000_add_artist_to_links.rb`
- Modify: `db/schema.rb`

- [ ] **Step 1: Write the failing model test**

```ruby
require "rails_helper"

RSpec.describe Link do
  it "defaults to a non-artist" do
    expect(described_class.new).not_to be_artist
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.local/bin/bundle exec rspec spec/models/link_spec.rb`

Expected: FAIL because `Link` does not expose an `artist` attribute or `artist?` predicate.

- [ ] **Step 3: Add the migration**

```ruby
class AddArtistToLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :links, :artist, :boolean, default: false, null: false
  end
end
```

- [ ] **Step 4: Migrate the development and test databases**

Run: `.local/bin/bundle exec rails db:migrate`

Expected: exit 0; `db/schema.rb` contains `t.boolean "artist", default: false, null: false` and schema version `2026_07_12_130000`.

Run: `RAILS_ENV=test .local/bin/bundle exec rails db:migrate`

Expected: exit 0.

- [ ] **Step 5: Run the model test to verify it passes**

Run: `.local/bin/bundle exec rspec spec/models/link_spec.rb`

Expected: 1 example, 0 failures.

- [ ] **Step 6: Commit the classification**

```bash
git add db/migrate/20260712130000_add_artist_to_links.rb db/schema.rb spec/models/link_spec.rb
git commit -m "Add artist classification to links"
```

### Task 2: Create artists through the admin Show form

**Files:**
- Modify: `spec/forms/admin/show_form_spec.rb`
- Modify: `app/forms/admin/show_form.rb`
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/views/pages/_admin_show_form.html.erb`

- [ ] **Step 1: Tighten the form persistence examples**

In `spec/forms/admin/show_form_spec.rb`, extend the existing `"combines unique existing links with multiple new links"` example after saving:

```ruby
expect(form.show.links.where(name: [ "Tickets", "Info" ])).to all(be_artist)
expect(existing.reload).not_to be_artist
```

Extend `"creates a new venue and link while editing"` with:

```ruby
expect(show.links.first).to be_artist
```

- [ ] **Step 2: Run the focused form examples to verify they fail**

Run: `.local/bin/bundle exec rspec spec/forms/admin/show_form_spec.rb -e "combines unique existing links" -e "creates a new venue and link while editing"`

Expected: 2 failures because new links still receive the database default `artist: false`.

- [ ] **Step 3: Mark normalized new links as artists**

Change `normalized_new_links` in `app/forms/admin/show_form.rb` to add the server-owned classification:

```ruby
def normalized_new_links
  submitted_new_links.filter_map do |row|
    row.symbolize_keys.merge(artist: true) if row.values.any?(&:present?)
  end
end
```

- [ ] **Step 4: Run the focused form examples to verify they pass**

Run: `.local/bin/bundle exec rspec spec/forms/admin/show_form_spec.rb -e "combines unique existing links" -e "creates a new venue and link while editing"`

Expected: 2 examples, 0 failures.

- [ ] **Step 5: Write the failing admin terminology expectation**

In the existing `"renders the two-panel show form for an admin"` view example, replace the generic link-controller-only assertions with user-facing Artist assertions while retaining the controller assertions:

```ruby
expect(rendered).to include("Show details and Artists")
expect(rendered).to include("Existing Artists", "New Artists", "Add another Artist")
expect(rendered).not_to include("Existing Links", "New Links", "Add another Link")
expect(rendered).to include('data-controller="link-rows"')
expect(rendered).to include('data-action="link-rows#add"')
expect(rendered).to include('data-action="link-rows#remove"')
```

- [ ] **Step 6: Run the terminology example to verify it fails**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb -e "renders the two-panel show form for an admin"`

Expected: FAIL because the form still displays Link terminology.

- [ ] **Step 7: Rename user-facing form text**

In `app/views/pages/_admin_show_form.html.erb`, make these exact text substitutions without renaming parameter keys or Stimulus identifiers:

```text
Show details and Links -> Show details and Artists
Existing Links -> Existing Artists
No existing Links. -> No existing Artists.
New Links -> New Artists
Add another Link -> Add another Artist
```

- [ ] **Step 8: Run the form and view specs**

Run: `.local/bin/bundle exec rspec spec/forms/admin/show_form_spec.rb spec/views/pages/home.html.erb_spec.rb`

Expected: all examples pass with 0 failures.

- [ ] **Step 9: Commit admin artist creation**

```bash
git add app/forms/admin/show_form.rb app/views/pages/_admin_show_form.html.erb spec/forms/admin/show_form_spec.rb spec/views/pages/home.html.erb_spec.rb
git commit -m "Create artists from show form"
```

### Task 3: Render artists in the public Shows table

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/views/pages/home.html.erb`

- [ ] **Step 1: Replace the generic links-cell example with the artist behavior**

Replace `"links a venue with a map URL and renders all Show links in the links cell"` with:

```ruby
it "links the venue and renders only artists as a prefixed comma-separated list" do
  venue = Venue.new(
    name: "Union Hall", city: "Brooklyn", state: "NY",
    map_url: "https://maps.example/union"
  )
  show = Show.new(date: Date.new(2026, 7, 10), time: "19:30", price: "$15", venue: venue)
  show.links = [
    Link.new(name: "Artist One", url: "https://example.com/one", artist: true),
    Link.new(name: "Tickets", url: "https://example.com/tickets", artist: false),
    Link.new(name: "Artist Two", url: "https://example.com/two", artist: true)
  ]

  assign(:shows, [ show ])
  render template: "pages/home"
  row = Nokogiri::HTML.fragment(rendered).css(".shows-table tr").first
  artists = row.at_css(".shows-table__artists")

  expect(row.at_css('a[href="https://maps.example/union"]')&.text).to eq("Union Hall")
  expect(artists.text.squish).to eq("w/ Artist One, Artist Two")
  expect(artists.css("a").map { |anchor| [ anchor.text, anchor["href"] ] }).to eq([
    [ "Artist One", "https://example.com/one" ],
    [ "Artist Two", "https://example.com/two" ]
  ])
  expect(row).not_to have_link("Tickets")
end
```

Update `"keeps an unlinked venue name and an empty final cell when no URLs exist"` to find the semantic cell directly:

```ruby
expect(row.at_css(".shows-table__artists").text.strip).to be_empty
```

- [ ] **Step 2: Run the two public-cell examples to verify they fail**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb -e "renders only artists" -e "keeps an unlinked venue"`

Expected: failures because `.shows-table__artists` does not exist and all associated links are currently rendered.

- [ ] **Step 3: Render the Artists cell**

Replace the `.shows-table__links` cell in `app/views/pages/home.html.erb` with:

```erb
<td class="shows-table__artists">
  <% artists = show.links.select(&:artist?) %>
  <% if artists.any? %>
    w/
    <% artists.each_with_index do |artist, index| %><%= ", " unless index.zero? %><%= link_to artist.name, artist.url %><% end %>
  <% end %>
</td>
```

- [ ] **Step 4: Run the complete view spec**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: all examples pass with 0 failures.

- [ ] **Step 5: Commit public artist rendering**

```bash
git add app/views/pages/home.html.erb spec/views/pages/home.html.erb_spec.rb
git commit -m "Display artists in shows table"
```

### Task 4: Full verification

**Files:**
- Verify all modified files from Tasks 1-3.

- [ ] **Step 1: Run the complete RSpec suite**

Run: `.local/bin/bundle exec rspec`

Expected: 0 failures.

- [ ] **Step 2: Run RuboCop**

Run: `.local/bin/bundle exec rubocop`

Expected: exit 0 with no offenses.

- [ ] **Step 3: Check migration state and diff hygiene**

Run: `.local/bin/bundle exec rails db:migrate:status`

Expected: `20260712130000 Add artist to links` is `up`.

Run: `git diff --check`

Expected: no output and exit 0.

- [ ] **Step 4: Review requirements against the final diff**

Run: `git diff HEAD~3 -- db/migrate/20260712130000_add_artist_to_links.rb db/schema.rb app/forms/admin/show_form.rb app/views/pages/_admin_show_form.html.erb app/views/pages/home.html.erb spec/models/link_spec.rb spec/forms/admin/show_form_spec.rb spec/views/pages/home.html.erb_spec.rb`

Expected: the diff contains the false/non-null schema default, server-owned `artist: true` creation, Artist form terminology, filtered `w/` rendering, and the corresponding tests; it contains no unrelated changes.
