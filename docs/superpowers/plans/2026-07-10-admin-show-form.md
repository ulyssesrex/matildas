# Admin Show Form Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an admin-only form below the Shows table that atomically creates a Show with an optional existing-or-new Venue and any number of existing or new Links.

**Architecture:** A dedicated `Admin::ShowForm` validates the cross-record submission and persists it in one transaction. `Admin::ShowsController` enforces admin authorization and renders the public home template on errors; a focused partial and Stimulus controller provide the responsive two-panel UI and dynamic Link rows.

**Tech Stack:** Rails 8.1, Active Record, Active Model, ERB, Stimulus, CSS, RSpec

---

## File Map

- Create `app/forms/admin/show_form.rb`: form-specific attributes, validation, Eastern-time parsing, record lookup, and atomic persistence.
- Create `app/controllers/admin/shows_controller.rb`: admin-only create endpoint and success/failure responses.
- Create `app/views/pages/_admin_show_form.html.erb`: two-panel form, errors, Venue selection, Link selection, and nested new-Link inputs.
- Create `app/javascript/controllers/link_rows_controller.js`: add/remove dynamic Link rows.
- Create `spec/forms/admin/show_form_spec.rb`: form validation, persistence, timezone, and atomicity coverage.
- Create `spec/requests/admin_shows_spec.rb`: authorization and endpoint behavior.
- Modify `app/controllers/concerns/authentication.rb`: expose current-user/admin predicates and admin authorization.
- Modify `app/controllers/pages_controller.rb`: prepare admin form choices on GET and via reusable helper.
- Modify `app/views/pages/home.html.erb`: conditionally render the form and display flash messages.
- Modify `app/assets/stylesheets/application.css`: two-column form layout, errors, fields, and mobile stacking.
- Modify `config/routes.rb`: add the admin Shows create route.
- Modify existing request/view specs for form visibility and rendering.

### Task 1: Admin Identity and Create Route

**Files:**
- Modify: `app/controllers/concerns/authentication.rb`
- Modify: `config/routes.rb`
- Test: `spec/requests/admin_shows_spec.rb`

- [ ] **Step 1: Write failing authorization and routing specs**

Create request examples that POST `admin_shows_path` while signed out and assert a redirect to `new_admin_session_path`. Add a routing expectation that `POST /admin/shows` routes to `admin/shows#create`.

```ruby
RSpec.describe "Admin shows", type: :request do
  describe "POST /admin/shows" do
    it "redirects unauthenticated visitors to admin login" do
      post admin_shows_path, params: { admin_show_form: {} }
      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end
```

- [ ] **Step 2: Run the focused spec and confirm the red state**

Run: `script/rails5 bundle exec rspec spec/requests/admin_shows_spec.rb`

Expected: failure because `admin_shows_path` and `Admin::ShowsController` do not exist.

- [ ] **Step 3: Add route and reusable authorization predicates**

Add `resources :shows, only: :create` inside the existing `admin` namespace. In `Authentication`, expose `current_user` and `admin?` as helper methods and add `require_admin`:

```ruby
included do
  before_action :require_authentication
  helper_method :authenticated?, :current_user, :admin?
end

def current_user
  resume_session&.user
end

def admin?
  current_user&.admin?
end

def require_admin
  return if admin?
  return request_authentication unless authenticated?

  head :forbidden
end
```

Create the controller shell with `before_action :require_admin` and an empty `create` action so the route can resolve.

- [ ] **Step 4: Run the focused spec**

Run: `script/rails5 bundle exec rspec spec/requests/admin_shows_spec.rb`

Expected: the unauthenticated example passes.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/concerns/authentication.rb app/controllers/admin/shows_controller.rb config/routes.rb spec/requests/admin_shows_spec.rb
git commit -m "Add admin show creation endpoint"
```

### Task 2: Form Object Validation and Time Parsing

**Files:**
- Create: `app/forms/admin/show_form.rb`
- Create: `spec/forms/admin/show_form_spec.rb`

- [ ] **Step 1: Write failing specs for required fields and Eastern time**

Cover missing Date/Time/Price and assert that `date: "2026-07-10", time: "19:30"` produces `Time.utc(2026, 7, 10, 23, 30)` while `date: "2026-12-10", time: "19:30"` produces `Time.utc(2026, 12, 11, 0, 30)`.

```ruby
form = described_class.new(date: "2026-07-10", time: "19:30", price: "$15")
expect { form.save }.to change(Show, :count).by(1)
expect(Show.last.time).to eq(Time.utc(2026, 7, 10, 23, 30))
```

- [ ] **Step 2: Run the form spec and confirm the red state**

Run: `script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: failure because `Admin::ShowForm` is undefined.

- [ ] **Step 3: Implement the minimal form API and Show persistence**

Use `ActiveModel::Model` and `ActiveModel::Attributes`, define string attributes for scalar fields, arrays/hashes for Link inputs, validate presence, and parse inside the Eastern zone:

```ruby
module Admin
  class ShowForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :date, :string
    attribute :time, :string
    attribute :price, :string
    attribute :venue_id, :string
    attr_accessor :link_ids, :new_venue, :new_links
    attr_reader :show

    validates :date, :time, :price, presence: true
    validate :timestamp_is_valid

    def save
      return false unless valid?

      @show = Show.create!(time: parsed_time, price: price)
      true
    rescue ActiveRecord::RecordInvalid => error
      errors.add(:base, error.record.errors.full_messages.to_sentence)
      false
    end

    private

      def parsed_time
        @parsed_time ||= Time.use_zone("Eastern Time (US & Canada)") do
          Time.zone.parse("#{date} #{time}")
        end
      end

      def timestamp_is_valid
        errors.add(:time, "is invalid") unless date.present? && time.present? && parsed_time
      rescue ArgumentError
        errors.add(:time, "is invalid")
      end
  end
end
```

Use strict component comparison after parsing so normalized invalid dates such as February 30 are rejected instead of rolled forward.

- [ ] **Step 4: Run the focused form specs**

Run: `script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: required-field and DST/standard-time examples pass.

- [ ] **Step 5: Commit**

```bash
git add app/forms/admin/show_form.rb spec/forms/admin/show_form_spec.rb
git commit -m "Add admin show form time handling"
```

### Task 3: Venue and Link Validation

**Files:**
- Modify: `app/forms/admin/show_form.rb`
- Modify: `spec/forms/admin/show_form_spec.rb`

- [ ] **Step 1: Write failing validation specs**

Add examples for an existing Venue, a complete new Venue, conflicting existing/new Venue input, a partial new Venue, unknown Venue ID, unknown Link IDs, paired new Link fields, blank Link rows, and duplicate existing Link IDs.

```ruby
form = described_class.new(valid_attributes.merge(
  venue_id: venue.id,
  new_venue: { name: "Other", city: "Boston", state: "MA", map_url: "https://maps.example/other" }
))
expect(form).not_to be_valid
expect(form.errors[:venue]).to include("choose an existing venue or create a new venue, not both")
```

- [ ] **Step 2: Run the focused specs and confirm failures**

Run: `script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: new Venue/Link rules fail because they are not implemented.

- [ ] **Step 3: Normalize nested inputs and implement validations**

Normalize blank Rails checkbox values, indexed hashes, and string-keyed hashes. Validate IDs through `Venue.where(id: ...)` and `Link.where(id: ...)`; compare resolved counts to normalized unique IDs. Add conditional completeness checks:

```ruby
VENUE_FIELDS = %w[name city state map_url].freeze

def normalized_new_venue
  @normalized_new_venue ||= (new_venue || {}).to_h.stringify_keys.slice(*VENUE_FIELDS)
end

def new_venue_started?
  normalized_new_venue.values.any?(&:present?)
end

def validate_venue_choice
  if venue_id.present? && new_venue_started?
    errors.add(:venue, "choose an existing venue or create a new venue, not both")
  elsif new_venue_started?
    VENUE_FIELDS.each do |field|
      errors.add("new_venue_#{field}", "can't be blank") if normalized_new_venue[field].blank?
    end
  end
end
```

For each nonblank normalized Link row, require both `name` and `url`. Ignore a row only when both values are blank.

- [ ] **Step 4: Run the focused form specs**

Run: `script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: all validation examples pass.

- [ ] **Step 5: Commit**

```bash
git add app/forms/admin/show_form.rb spec/forms/admin/show_form_spec.rb
git commit -m "Validate show venue and link inputs"
```

### Task 4: Atomic Multi-Record Persistence

**Files:**
- Modify: `app/forms/admin/show_form.rb`
- Modify: `spec/forms/admin/show_form_spec.rb`

- [ ] **Step 1: Write failing persistence and rollback specs**

Assert that one submission can create a Show, create and associate one Venue, associate selected existing Links, create multiple new Links, and create all join rows. Stub a new Link save to fail and assert no involved table count changes.

```ruby
expect { form.save }
  .to change(Show, :count).by(1)
  .and change(Venue, :count).by(1)
  .and change(Link, :count).by(2)

expect(form.show.links).to contain_exactly(existing_link, Link.find_by!(name: "Tickets"), Link.find_by!(name: "Info"))
```

- [ ] **Step 2: Run specs and confirm persistence failures**

Run: `script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: association and rollback examples fail.

- [ ] **Step 3: Implement the transaction**

Resolve existing records before entering the transaction. Within `ApplicationRecord.transaction`, create the optional Venue, create the Show, assign existing Links, create new Links, and append them to the Show. Rescue `RecordInvalid` and attach a base error without leaking partial state.

```ruby
ApplicationRecord.transaction do
  venue = existing_venue || (Venue.create!(normalized_new_venue) if new_venue_started?)
  @show = Show.create!(time: parsed_time, price: price, venue: venue)
  @show.links = existing_links
  normalized_new_links.each { |attributes| @show.links << Link.create!(attributes) }
end
```

- [ ] **Step 4: Run all form specs**

Run: `script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb`

Expected: all examples pass with zero failures.

- [ ] **Step 5: Commit**

```bash
git add app/forms/admin/show_form.rb spec/forms/admin/show_form_spec.rb
git commit -m "Persist admin show submissions atomically"
```

### Task 5: Controller Flow and Admin Authorization

**Files:**
- Modify: `app/controllers/admin/shows_controller.rb`
- Modify: `app/controllers/pages_controller.rb`
- Modify: `spec/requests/admin_shows_spec.rb`

- [ ] **Step 1: Write failing request specs**

Add helpers that sign in through `POST /admin/session`. Cover forbidden non-admin POSTs, successful admin creation and redirect to `/#shows`, invalid submission rendering with status 422 and preserved text, and full existing/new Venue and Link parameters.

```ruby
post admin_shows_path, params: {
  admin_show_form: {
    date: "2026-07-10", time: "19:30", price: "$15",
    venue_id: venue.id,
    link_ids: [existing_link.id],
    new_links: { "0" => { name: "Tickets", url: "https://example.com/tickets" } }
  }
}
expect(response).to redirect_to(root_path(anchor: "shows"))
```

- [ ] **Step 2: Run request specs and confirm failures**

Run: `script/rails5 bundle exec rspec spec/requests/admin_shows_spec.rb`

Expected: create-flow examples fail because the action is empty.

- [ ] **Step 3: Implement controller create and shared page preparation**

Give `PagesController` a callable `prepare_home` method that loads Shows and, for admins, sorted Venue/Link choices plus a default form. In `Admin::ShowsController#create`, instantiate the form from permitted nested parameters, redirect on success, and on failure call `prepare_home`, then render `pages/home` with status `:unprocessable_content`.

Permit exactly:

```ruby
params.expect(admin_show_form: [
  :date, :time, :price, :venue_id,
  { link_ids: [], new_venue: %i[name city state map_url], new_links: [[:name, :url]] }
])
```

- [ ] **Step 4: Run request specs**

Run: `script/rails5 bundle exec rspec spec/requests/admin_shows_spec.rb spec/requests/pages_spec.rb`

Expected: authorization, redirect, and invalid-render examples pass.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/admin/shows_controller.rb app/controllers/pages_controller.rb spec/requests/admin_shows_spec.rb
git commit -m "Handle admin show form submissions"
```

### Task 6: Admin-Only Two-Panel Form

**Files:**
- Create: `app/views/pages/_admin_show_form.html.erb`
- Modify: `app/views/pages/home.html.erb`
- Modify: `app/assets/stylesheets/application.css`
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `spec/requests/pages_spec.rb`

- [ ] **Step 1: Write failing visibility and rendering specs**

Assert the form is absent for anonymous and non-admin page requests and present for an authenticated admin. In the view spec, assign the form and choices, stub `admin?` true, and assert labels for Date, Time, Price, Venue fields, existing Link checkboxes, the Link row template, and the Create Show button.

- [ ] **Step 2: Run focused specs and confirm failures**

Run: `script/rails5 bundle exec rspec spec/views/pages/home.html.erb_spec.rb spec/requests/pages_spec.rb`

Expected: admin form markup expectations fail.

- [ ] **Step 3: Render the form conditionally and add complete markup**

In `home.html.erb`, render flash messages and:

```erb
<%= render "pages/admin_show_form", form: @show_form,
      venues: @venues, links: @links if admin? %>
```

Use `form_with model: form, url: admin_shows_path`, an error summary, two `.admin-show-form__panel` elements, checkbox names `admin_show_form[link_ids][]`, and indexed new-Link names. Include a `<template data-link-rows-target="template">` whose `NEW_RECORD` placeholder is replaced by the Stimulus controller.

- [ ] **Step 4: Add responsive styling**

Define a two-column CSS grid at desktop widths, consistent label/input/error styles, checkbox layout, and `grid-template-columns: 1fr` below `48rem`. Preserve the existing horizontal scrolling behavior for the Shows table.

- [ ] **Step 5: Run view and page request specs**

Run: `script/rails5 bundle exec rspec spec/views/pages/home.html.erb_spec.rb spec/requests/pages_spec.rb`

Expected: all examples pass.

- [ ] **Step 6: Commit**

```bash
git add app/views/pages/_admin_show_form.html.erb app/views/pages/home.html.erb app/assets/stylesheets/application.css spec/views/pages/home.html.erb_spec.rb spec/requests/pages_spec.rb
git commit -m "Add admin show form to home page"
```

### Task 7: Dynamic Link Rows

**Files:**
- Create: `app/javascript/controllers/link_rows_controller.js`
- Modify: `app/views/pages/_admin_show_form.html.erb`
- Test: `spec/views/pages/home.html.erb_spec.rb`

- [ ] **Step 1: Add failing markup assertions**

Assert the form contains `data-controller="link-rows"`, a template target, a rows target, and buttons wired to `link-rows#add` and `link-rows#remove`.

- [ ] **Step 2: Run the view spec and confirm the red state**

Run: `script/rails5 bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: missing Stimulus hooks.

- [ ] **Step 3: Implement the Stimulus controller**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "rows"]

  add() {
    const key = `${Date.now()}-${Math.random().toString(16).slice(2)}`
    this.rowsTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_RECORD", key))
  }

  remove(event) {
    event.currentTarget.closest("[data-link-row]").remove()
  }
}
```

Wire one initial blank row and every validation-error row through the same partial markup so submitted data survives re-rendering.

- [ ] **Step 4: Run view specs**

Run: `script/rails5 bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: all Stimulus hook assertions pass.

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/link_rows_controller.js app/views/pages/_admin_show_form.html.erb spec/views/pages/home.html.erb_spec.rb
git commit -m "Add dynamic new link rows"
```

### Task 8: Full Verification

**Files:**
- Modify only files implicated by verification failures.

- [ ] **Step 1: Run the feature specs together**

Run: `script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb spec/requests/admin_shows_spec.rb spec/requests/pages_spec.rb spec/views/pages/home.html.erb_spec.rb`

Expected: zero failures.

- [ ] **Step 2: Run the full test suite**

Run: `script/rails5 bundle exec rspec`

Expected: zero failures.

- [ ] **Step 3: Run style checks**

Run: `script/rails5 bundle exec rubocop`

Expected: no offenses.

- [ ] **Step 4: Run security checks**

Run: `bin/brakeman --no-pager`

Expected: no new warnings.

- [ ] **Step 5: Inspect the final diff and repository state**

Run: `git diff HEAD~6 --check && git status --short`

Expected: no whitespace errors and only intentional changes, with no uncommitted implementation files.
