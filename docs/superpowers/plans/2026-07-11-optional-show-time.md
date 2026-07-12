# Optional Show Time Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Store every show with a required calendar date and an optional clock time, displaying an absent time as `TBD`.

**Architecture:** Replace the overloaded datetime with independent database date and time columns. Keep parsing and validation in `Admin::ShowForm`, put lifecycle and ordering queries on `Show`, and make the view format each value independently.

**Tech Stack:** Rails 8.1, Active Record, SQLite, ERB, RSpec

---

### Task 1: Replace the datetime schema

**Files:**
- Create: `db/migrate/20260711120000_split_show_date_and_time.rb`
- Modify: `db/schema.rb`

- [ ] **Step 1: Add the migration**

Create an explicit one-way migration that renames the old datetime before adding the new columns and converts existing values to Eastern local date/time:

```ruby
class SplitShowDateAndTime < ActiveRecord::Migration[8.1]
  class MigrationShow < ActiveRecord::Base
    self.table_name = "shows"
  end

  def up
    rename_column :shows, :time, :scheduled_at
    add_column :shows, :date, :date
    add_column :shows, :time, :time

    MigrationShow.reset_column_information
    MigrationShow.find_each do |show|
      eastern_time = show.scheduled_at&.in_time_zone("Eastern Time (US & Canada)")
      show.update_columns(
        date: eastern_time&.to_date,
        time: eastern_time&.strftime("%H:%M:%S")
      )
    end

    change_column_null :shows, :date, false
    remove_column :shows, :scheduled_at
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "A TBD show date cannot be represented by the former datetime column"
  end
end
```

- [ ] **Step 2: Apply the migration and verify the schema**

Normally run `bin/rails db:migrate` and expect success. This command must be skipped in the current environment because Ruby commands are unavailable. Update the checked-in schema to version `2026_07_11_120000`, with `t.date "date", null: false` and `t.time "time"` in `shows`.

- [ ] **Step 3: Commit the schema change**

```bash
git add db/migrate/20260711120000_split_show_date_and_time.rb db/schema.rb
git commit -m "Split show date and time fields"
```

### Task 2: Query shows by date and optional time

**Files:**
- Modify: `spec/models/show_spec.rb`
- Modify: `app/models/show.rb`
- Modify: `app/controllers/pages_controller.rb`
- Modify: `app/controllers/admin/shows_controller.rb`

- [ ] **Step 1: Write failing scope and ordering specs**

Replace datetime fixtures with required dates and add an ordering example:

```ruby
describe "unexpired scope" do
  it "uses the show date, including when time is absent" do
    freeze_time do
      expired = Show.create!(date: 15.days.ago.to_date, price: "$15")
      boundary = Show.create!(date: 14.days.ago.to_date, price: "$15")
      future_tbd = Show.create!(date: 1.month.from_now.to_date, time: nil, price: "$15")

      expect(Show.unexpired).to contain_exactly(boundary, future_tbd)
      expect(Show.unexpired).not_to include(expired)
    end
  end
end

describe "chronological scope" do
  it "orders by date and puts known times before TBD times" do
    tbd = Show.create!(date: Date.new(2026, 7, 10), time: nil, price: "$15")
    late = Show.create!(date: Date.new(2026, 7, 10), time: "20:00", price: "$15")
    early = Show.create!(date: Date.new(2026, 7, 10), time: "19:00", price: "$15")
    next_day = Show.create!(date: Date.new(2026, 7, 11), time: "18:00", price: "$15")

    expect(Show.chronological).to eq([early, late, tbd, next_day])
  end
end
```

- [ ] **Step 2: Run the model spec and verify RED**

Normally run `bundle exec rspec spec/models/show_spec.rb`; expect failures because the scopes still use the old datetime semantics. Skip this command in the current environment.

- [ ] **Step 3: Implement the scopes**

```ruby
scope :unexpired, -> { where(date: 2.weeks.ago.to_date..) }
scope :chronological, -> { order(:date, Arel.sql("time IS NULL"), :time) }
```

Replace each controller chain ending in `.order(:time)` with `.chronological`.

- [ ] **Step 4: Run the model and request specs and verify GREEN**

Normally run `bundle exec rspec spec/models/show_spec.rb spec/requests/admin_shows_spec.rb`; expect passing output. Skip this command in the current environment.

- [ ] **Step 5: Commit the query changes**

```bash
git add app/models/show.rb app/controllers/pages_controller.rb app/controllers/admin/shows_controller.rb spec/models/show_spec.rb
git commit -m "Query shows by date and optional time"
```

### Task 3: Save and edit optional times

**Files:**
- Modify: `spec/forms/admin/show_form_spec.rb`
- Modify: `app/forms/admin/show_form.rb`
- Modify: `app/views/pages/_admin_show_form.html.erb`

- [ ] **Step 1: Write failing form specs**

Change the required-fields example to require only date and price. Add examples proving direct storage and blank-time editing:

```ruby
it "saves a required date with no time" do
  form = described_class.new(date: "2026-07-10", time: "", price: "$15")

  expect(form.save).to be(true)
  expect(form.show).to have_attributes(date: Date.new(2026, 7, 10), time: nil)
end

it "stores a supplied local clock time without UTC conversion" do
  expect(form.save).to be(true)
  expect(form.show.date).to eq(Date.new(2026, 7, 10))
  expect(form.show.time.strftime("%H:%M")).to eq("19:30")
end

it "prefills a TBD show with a blank time" do
  show = Show.create!(date: Date.new(2026, 7, 10), time: nil, price: "$15")

  expect(described_class.new(show: show)).to have_attributes(date: "2026-07-10", time: nil)
end
```

Update all existing `Show.create!` calls and expectations in this spec to use `date:` plus a clock-only `time:`.

- [ ] **Step 2: Run the form spec and verify RED**

Normally run `bundle exec rspec spec/forms/admin/show_form_spec.rb`; expect blank time to fail validation and existing datetime assertions to fail. Skip this command in the current environment.

- [ ] **Step 3: Implement independent parsing and persistence**

Require only date and price:

```ruby
validates :date, :price, presence: true
```

Persist both parsed values:

```ruby
@show.update!(date: parsed_date, time: parsed_time, price: price, venue: venue)
```

Read them independently during editing:

```ruby
{
  date: show.date&.iso8601,
  time: show.time&.strftime("%H:%M"),
  price: show.price,
  venue_id: show.venue_id&.to_s,
  link_ids: show.link_ids.map(&:to_s)
}
```

Replace `parsed_time` with a clock-only parser:

```ruby
def parsed_time
  return if time.blank? || parsed_time_parts.nil?

  Time.zone.local(2000, 1, 1, *parsed_time_parts)
end
```

- [ ] **Step 4: Make the HTML time input optional**

Change the field to:

```erb
<%= show_fields.time_field :time %>
```

- [ ] **Step 5: Run the form spec and verify GREEN**

Normally run `bundle exec rspec spec/forms/admin/show_form_spec.rb`; expect passing output. Skip this command in the current environment.

- [ ] **Step 6: Commit the form behavior**

```bash
git add app/forms/admin/show_form.rb app/views/pages/_admin_show_form.html.erb spec/forms/admin/show_form_spec.rb
git commit -m "Allow admin shows to omit time"
```

### Task 4: Display unknown times as TBD

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/views/pages/home.html.erb`

- [ ] **Step 1: Write the failing view spec**

Update fixtures to use separate values and add:

```ruby
it "renders TBD when a show has no time" do
  show = Show.new(date: Date.new(2026, 7, 10), time: nil, price: "$15")
  assign(:shows, [show])

  render template: "pages/home"

  row = Nokogiri::HTML.fragment(rendered).at_css(".shows-table tr")
  expect(row.css("td")[0].text).to include("July 10, 2026")
  expect(row.css("td")[1].text.strip).to eq("TBD")
end
```

- [ ] **Step 2: Run the view spec and verify RED**

Normally run `bundle exec rspec spec/views/pages/home.html.erb_spec.rb`; expect an error from calling `in_time_zone` on `nil`. Skip this command in the current environment.

- [ ] **Step 3: Render date and time independently**

Replace the datetime conversion and first two cells with:

```erb
<td><%= show.date.strftime("%B %-d, %Y") %></td>
<td><%= show.time&.strftime("%-l:%M %p") || "TBD" %></td>
```

- [ ] **Step 4: Run the view spec and verify GREEN**

Normally run `bundle exec rspec spec/views/pages/home.html.erb_spec.rb`; expect passing output. Skip this command in the current environment.

- [ ] **Step 5: Commit the display change**

```bash
git add app/views/pages/home.html.erb spec/views/pages/home.html.erb_spec.rb
git commit -m "Display TBD for unknown show times"
```

### Task 5: Cover admin creation and editing end to end

**Files:**
- Modify: `spec/requests/admin_shows_spec.rb`

- [ ] **Step 1: Update known-time request expectations**

Replace datetime setup and assertions with required dates and clock-only times, using `show.time.strftime("%H:%M")` when asserting the clock value.

- [ ] **Step 2: Add blank-time request examples**

Add creation and update coverage:

```ruby
it "creates a show with a TBD time" do
  admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
  sign_in(admin)

  post admin_shows_path, params: {
    admin_show_form: { date: "2026-07-10", time: "", price: "$15" }
  }

  expect(response).to redirect_to(root_path(anchor: "shows"))
  expect(Show.last).to have_attributes(date: Date.new(2026, 7, 10), time: nil)
end

it "updates a show to have a TBD time" do
  admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
  sign_in(admin)

  patch admin_show_path(show), params: {
    admin_show_form: { date: "2026-08-12", time: "", price: "$20" }
  }

  expect(response).to redirect_to(root_path)
  expect(show.reload).to have_attributes(date: Date.new(2026, 8, 12), time: nil, price: "$20")
end
```

- [ ] **Step 3: Run request specs and verify GREEN**

Normally run `bundle exec rspec spec/requests/admin_shows_spec.rb`; expect passing output. Skip this command in the current environment.

- [ ] **Step 4: Perform available verification**

Run `git diff --check` and targeted `rg` searches for old UTC datetime expectations, `.order(:time)`, and `show.time.in_time_zone`. Expect no whitespace errors or stale production references. Do not claim runtime verification.

- [ ] **Step 5: Commit request coverage**

```bash
git add spec/requests/admin_shows_spec.rb
git commit -m "Cover TBD show time admin flows"
```
