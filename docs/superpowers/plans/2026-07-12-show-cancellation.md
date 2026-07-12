# Show Cancellation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let admins cancel and uncancel shows while preserving both ordinary and cancellation notes and clearly rendering cancelled shows in the Shows table.

**Architecture:** Persist cancellation state and cancellation notes on `Show`, while retaining the existing ordinary `notes` column. Extend the existing form object and controller permit list, use a small Stimulus controller to switch between two independently submitted note fields, and make the table choose its time, notes, and styling from `cancelled`.

**Tech Stack:** Rails 8.1, Active Record/SQLite, ActiveModel form object, ERB, Stimulus, CSS, RSpec/Nokogiri

---

## File Structure

- Create `db/migrate/20260712120000_add_cancellation_to_shows.rb`: add cancellation persistence with safe defaults.
- Modify `db/schema.rb`: generated schema representation after migration.
- Modify `app/forms/admin/show_form.rb`: expose, prefill, and transactionally persist cancellation and both notes fields.
- Modify `app/controllers/admin/shows_controller.rb`: permit cancellation form parameters.
- Modify `app/views/pages/_admin_show_form.html.erb`: render the checkbox and independently persisted note fields.
- Create `app/javascript/controllers/show_cancellation_controller.js`: switch visible note field when cancellation state changes.
- Modify `app/views/pages/home.html.erb`: render active/cancelled time and notes and identify cancelled rows.
- Modify `app/assets/stylesheets/application.css`: style cancelled table rows red and support note textareas/hidden form sections.
- Modify `spec/models/show_spec.rb`: verify database defaults.
- Modify `spec/forms/admin/show_form_spec.rb`: verify form persistence, prefilling, preservation, optional notes, and rollback.
- Modify `spec/requests/admin_shows_spec.rb`: verify permitted cancellation attributes reach persistence.
- Modify `spec/views/pages/home.html.erb_spec.rb`: verify table substitution/styling and form wiring/initial state.

### Task 1: Add Show Cancellation Persistence

**Files:**
- Create: `db/migrate/20260712120000_add_cancellation_to_shows.rb`
- Modify: `db/schema.rb`
- Test: `spec/models/show_spec.rb`

- [ ] **Step 1: Write the failing default-value spec**

Add to `spec/models/show_spec.rb`:

```ruby
it "defaults new persisted shows to active with no cancellation notes" do
  show = Show.create!(date: Date.new(2026, 7, 10), price: "$15")

  expect(show).to have_attributes(cancelled: false, cancellation_notes: nil)
end
```

- [ ] **Step 2: Run the model spec and verify RED**

Run: `.local/bin/bundle exec rspec spec/models/show_spec.rb`

Expected: FAIL because `Show` has no `cancelled` or `cancellation_notes` attributes.

- [ ] **Step 3: Add and run the migration**

Create:

```ruby
class AddCancellationToShows < ActiveRecord::Migration[8.1]
  def change
    add_column :shows, :cancelled, :boolean, default: false, null: false
    add_column :shows, :cancellation_notes, :text
  end
end
```

Run: `.local/bin/bundle exec rails db:migrate`

Expected: migration succeeds and regenerates `db/schema.rb` with schema version `2026_07_12_120000` and both columns.

- [ ] **Step 4: Run the model spec and verify GREEN**

Run: `.local/bin/bundle exec rspec spec/models/show_spec.rb`

Expected: all examples pass.

- [ ] **Step 5: Commit persistence changes**

```bash
git add db/migrate/20260712120000_add_cancellation_to_shows.rb db/schema.rb spec/models/show_spec.rb
git commit -m "Add show cancellation fields"
```

### Task 2: Persist Cancellation Through the Admin Form

**Files:**
- Modify: `spec/forms/admin/show_form_spec.rb`
- Modify: `app/forms/admin/show_form.rb`

- [ ] **Step 1: Write failing creation, optional-notes, editing, and rollback specs**

Add examples that create a form with `cancelled: "1"`, ordinary notes, and cancellation notes, then assert all three values persist. Add a second example with `cancelled: "1"` and blank cancellation notes and assert `save` is true.

```ruby
it "persists cancellation state and both kinds of notes" do
  form = described_class.new(attributes.merge(
    cancelled: "1", notes: "Doors at 7", cancellation_notes: "Venue closed"
  ))

  expect(form.save).to be(true)
  expect(form.show).to have_attributes(
    cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
  )
end

it "allows a cancelled show without cancellation notes" do
  form = described_class.new(attributes.merge(cancelled: "1", cancellation_notes: ""))

  expect(form.save).to be(true)
  expect(form.show).to have_attributes(cancelled: true, cancellation_notes: "")
end
```

Also create an ordinary-notes show, cancel it with cancellation notes, then uncancel it in a second form submission while passing both stored note values. Assert ordinary notes survive both transitions and the form prefills both values. Extend the existing rollback example to submit changed cancellation state and notes and assert the original values remain after the associated-record failure.

```ruby
it "prefills and preserves both notes through cancellation changes" do
  show.update!(notes: "Doors at 7")

  cancel_form = described_class.new(
    show: show, date: "2026-07-10", time: "19:30", price: "$15",
    cancelled: "1", notes: "Doors at 7", cancellation_notes: "Venue closed"
  )
  expect(cancel_form.save).to be(true)

  prefilled = described_class.new(show: show.reload)
  expect(prefilled).to have_attributes(
    cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
  )

  active_form = described_class.new(
    show: show, date: "2026-07-10", time: "19:30", price: "$15",
    cancelled: "0", notes: "Doors at 7", cancellation_notes: "Venue closed"
  )
  expect(active_form.save).to be(true)
  expect(show.reload).to have_attributes(
    cancelled: false, notes: "Doors at 7", cancellation_notes: "Venue closed"
  )
end
```

- [ ] **Step 2: Run the focused form examples and verify RED**

Run: `.local/bin/bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: FAIL because the form object does not expose the new attributes.

- [ ] **Step 3: Implement form attributes and persistence**

Add typed/form attributes:

```ruby
attribute :cancelled, :boolean, default: false
attribute :notes, :string
attribute :cancellation_notes, :string
```

Include them in the existing update:

```ruby
@show.update!(
  date: parsed_date,
  time: parsed_time,
  price: price,
  venue: venue,
  cancelled: cancelled,
  notes: notes,
  cancellation_notes: cancellation_notes
)
```

Include them in `attributes_from_show`:

```ruby
cancelled: show.cancelled,
notes: show.notes,
cancellation_notes: show.cancellation_notes,
```

- [ ] **Step 4: Run the complete form spec and verify GREEN**

Run: `.local/bin/bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: all examples pass.

- [ ] **Step 5: Commit the form changes**

```bash
git add app/forms/admin/show_form.rb spec/forms/admin/show_form_spec.rb
git commit -m "Persist show cancellation in admin form"
```

### Task 3: Permit Cancellation Parameters in Admin Requests

**Files:**
- Modify: `spec/requests/admin_shows_spec.rb`
- Modify: `app/controllers/admin/shows_controller.rb`

- [ ] **Step 1: Write failing create and update request assertions**

Extend the admin create request attributes with `cancelled: "1"`, `notes: "Doors at 7"`, and `cancellation_notes: "Venue closed"`; assert the created show has all three. Extend the update example similarly, then assert the updated show has all three values.

- [ ] **Step 2: Run request specs and verify RED**

Run: `.local/bin/bundle exec rspec spec/requests/admin_shows_spec.rb`

Expected: FAIL because strong parameters discard the three attributes.

- [ ] **Step 3: Permit the scalar attributes**

Change the permit call to begin:

```ruby
params.require(:admin_show_form).permit(
  :date, :time, :price, :venue_id, :cancelled, :notes, :cancellation_notes,
```

- [ ] **Step 4: Run request specs and verify GREEN**

Run: `.local/bin/bundle exec rspec spec/requests/admin_shows_spec.rb`

Expected: all examples pass.

- [ ] **Step 5: Commit request-flow changes**

```bash
git add app/controllers/admin/shows_controller.rb spec/requests/admin_shows_spec.rb
git commit -m "Accept show cancellation parameters"
```

### Task 4: Render and Toggle the Two Admin Notes Fields

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/views/pages/_admin_show_form.html.erb`
- Create: `app/javascript/controllers/show_cancellation_controller.js`
- Modify: `app/assets/stylesheets/application.css`

- [ ] **Step 1: Write failing form-markup specs for active and cancelled state**

Render an active form and assert the form has `data-controller="show-cancellation"`, a checkbox targeting `cancelled`, a visible ordinary-notes wrapper, and a hidden cancellation-notes wrapper. Render a cancelled form and assert those hidden states reverse. Also assert each textarea contains its independently stored value.

```ruby
form = Admin::ShowForm.new(
  cancelled: true, notes: "Doors at 7", cancellation_notes: "Venue closed"
)
assign(:show_form, form)
assign(:shows, [])
assign(:venues, [])
assign(:links, [])
allow(view).to receive(:admin?).and_return(true)
render template: "pages/home"
fragment = Nokogiri::HTML.fragment(rendered)
expect(fragment.at_css('[data-controller="show-cancellation"]')).to be_present
expect(fragment.at_css('[data-show-cancellation-target="ordinaryNotes"][hidden]')).to be_present
expect(fragment.at_css('[data-show-cancellation-target="cancellationNotes"]')).to be_present
```

- [ ] **Step 2: Run view specs and verify RED**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: FAIL because the cancellation controls are absent.

- [ ] **Step 3: Add the form markup**

Inside the details fieldset, add a wrapper with `data-controller="show-cancellation"`, the checkbox with `data-action="show-cancellation#toggle"`, and two target wrappers. Set each wrapper's server-rendered `hidden` attribute from `form.cancelled` so the form is correct before Stimulus connects.

```erb
<div data-controller="show-cancellation">
  <div class="form-field">
    <label>
      <%= show_fields.check_box :cancelled,
            data: { action: "show-cancellation#toggle", show_cancellation_target: "checkbox" } %>
      Cancelled
    </label>
  </div>

  <div class="form-field" data-show-cancellation-target="ordinaryNotes" <%= "hidden" if form.cancelled %>>
    <%= show_fields.label :notes, "Notes" %>
    <%= show_fields.text_area :notes %>
  </div>

  <div class="form-field" data-show-cancellation-target="cancellationNotes" <%= "hidden" unless form.cancelled %>>
    <%= show_fields.label :cancellation_notes, "Cancellation notes" %>
    <%= show_fields.text_area :cancellation_notes %>
  </div>
</div>
```

- [ ] **Step 4: Add the focused Stimulus controller**

Create:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "ordinaryNotes", "cancellationNotes"]

  connect() {
    this.toggle()
  }

  toggle() {
    const cancelled = this.checkboxTarget.checked
    this.ordinaryNotesTarget.hidden = cancelled
    this.cancellationNotesTarget.hidden = !cancelled
  }
}
```

No manual registration is needed because `controllers/index.js` eager-loads `*_controller.js` files.

- [ ] **Step 5: Style textareas consistently**

Add `.form-field textarea` to the existing shared form-control selector and give it a practical vertical minimum/resize behavior:

```css
.form-field textarea {
  min-height: 6rem;
  resize: vertical;
}
```

- [ ] **Step 6: Run view specs and verify GREEN**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: all examples pass.

- [ ] **Step 7: Commit form interaction changes**

```bash
git add app/views/pages/_admin_show_form.html.erb app/javascript/controllers/show_cancellation_controller.js app/assets/stylesheets/application.css spec/views/pages/home.html.erb_spec.rb
git commit -m "Add cancellation controls to show form"
```

### Task 5: Render Cancelled Shows in the Shows Table

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/views/pages/home.html.erb`
- Modify: `app/assets/stylesheets/application.css`

- [ ] **Step 1: Write failing active-notes table spec**

Render an active show with `notes: "Doors at 7"`; assert the last public cell contains ordinary notes and the time remains formatted. Account for the admin-only Edit cell by selecting a dedicated `.shows-table__notes` cell.

- [ ] **Step 2: Run the focused view spec and verify RED**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: FAIL because the Notes cell is absent.

- [ ] **Step 3: Add the Notes cell for active shows**

Add:

```erb
<td class="shows-table__notes"><%= show.notes %></td>
```

- [ ] **Step 4: Run the focused spec and verify GREEN**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: the active-notes example passes.

- [ ] **Step 5: Write the failing cancelled-row spec**

Render a cancelled show containing both `notes: "Doors at 7"` and `cancellation_notes: "Venue closed"`. Assert its row has `.shows-table__row--cancelled`, its Time cell is exactly `SHOW CANCELLED`, its Notes cell contains `Venue closed`, and the row does not contain `Doors at 7`.

- [ ] **Step 6: Run the cancelled-row spec and verify RED**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: FAIL because cancelled substitution and row styling hooks are absent.

- [ ] **Step 7: Implement cancelled table rendering**

Use:

```erb
<tr class="<%= "shows-table__row--cancelled" if show.cancelled? %>">
```

Change the Time and Notes cells to:

```erb
<td><%= show.cancelled? ? "SHOW CANCELLED" : (show.time&.strftime("%-l:%M %p") || "TBD") %></td>
...
<td class="shows-table__notes"><%= show.cancelled? ? show.cancellation_notes : show.notes %></td>
```

Add CSS that also overrides link color:

```css
.shows-table__row--cancelled,
.shows-table__row--cancelled a {
  color: #ff3b3b;
}
```

- [ ] **Step 8: Run all view specs and verify GREEN**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: all examples pass, including existing link-cell assumptions updated to select `.shows-table__links` rather than `td:last` now that Notes follows Links.

- [ ] **Step 9: Commit table changes**

```bash
git add app/views/pages/home.html.erb app/assets/stylesheets/application.css spec/views/pages/home.html.erb_spec.rb
git commit -m "Display cancelled shows in red"
```

### Task 6: Full Verification

**Files:**
- Review all files modified above.

- [ ] **Step 1: Run the complete RSpec suite**

Run: `.local/bin/bundle exec rspec`

Expected: 0 failures.

- [ ] **Step 2: Run RuboCop**

Run: `.local/bin/bundle exec rubocop`

Expected: no offenses.

- [ ] **Step 3: Check migrations and diff hygiene**

Run: `.local/bin/bundle exec rails db:migrate:status`

Expected: `20260712120000 Add cancellation to shows` is `up`.

Run: `git diff --check`

Expected: no output and exit status 0.

- [ ] **Step 4: Review requirement coverage**

Confirm from the diff and specs that cancelled shows remain in the existing unexpired query, every cancelled row and link is red, Time reads exactly `SHOW CANCELLED`, cancellation notes replace ordinary notes only in cancelled display, both values persist, cancellation notes are optional, and uncancelling restores ordinary notes.

- [ ] **Step 5: Commit any verification-only corrections**

If verification required corrections, rerun the failing command and commit only those scoped corrections. If no corrections were needed, do not create an empty commit.
