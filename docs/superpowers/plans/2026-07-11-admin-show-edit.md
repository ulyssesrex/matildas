# Admin Show Editing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an admin-only Edit column to the Shows table and a separate form page that updates a Show and its Venue and Link associations before redirecting home.

**Architecture:** Extend the existing `Admin::ShowForm` with a record-backed update mode so create and edit share validation, nested association handling, and transactional persistence. Add RESTful edit/update actions to the existing admin controller and generalize the current form partial for both the home-page create form and the separate edit page.

**Tech Stack:** Rails 8.1, Active Record, Active Model, ERB, CSS, RSpec

**Environment constraint:** Do not invoke Ruby, Rails, Bundler, or RSpec commands in this workspace. The test commands below document the intended red/green checks for a working Ruby environment; here, use the listed static checks and report that runtime verification was unavailable.

---

## File Map

- Modify `app/forms/admin/show_form.rb`: accept an optional persisted Show, prefill its values, and update it transactionally.
- Modify `spec/forms/admin/show_form_spec.rb`: specify edit prepopulation, association replacement, new associated records, and rollback.
- Modify `config/routes.rb`: expose admin Show edit and update routes.
- Modify `app/controllers/admin/shows_controller.rb`: load Shows, render edit, process update, and prepare form choices.
- Modify `spec/requests/admin_shows_spec.rb`: cover edit/update authorization, rendering, success, and invalid submissions.
- Modify `app/views/pages/_admin_show_form.html.erb`: accept configurable URL, heading, submit label, and error action.
- Create `app/views/admin/shows/edit.html.erb`: provide the separate edit-page shell and render the shared form.
- Modify `app/views/pages/home.html.erb`: render an admin-only Edit cell for every Show.
- Modify `spec/views/pages/home.html.erb_spec.rb`: specify Edit controls for admins and their absence for visitors.
- Modify `app/assets/stylesheets/application.css`: make Edit links match the existing button language and constrain the edit page.

### Task 1: Record-Backed Show Form

**Files:**
- Modify: `spec/forms/admin/show_form_spec.rb`
- Modify: `app/forms/admin/show_form.rb`

- [ ] **Step 1: Write failing prepopulation and update specs**

Add examples that pass `show:` separately from submitted attributes:

```ruby
describe "editing" do
  let!(:venue) { Venue.create!(name: "Union Hall", city: "Brooklyn", state: "NY", map_url: "https://maps.example/union") }
  let!(:replacement_venue) { Venue.create!(name: "The Sinclair", city: "Cambridge", state: "MA", map_url: "https://maps.example/sinclair") }
  let!(:existing_link) { Link.create!(name: "Venue", url: "https://example.com/venue") }
  let!(:replacement_link) { Link.create!(name: "Details", url: "https://example.com/details") }
  let!(:show) do
    Show.create!(time: Time.utc(2026, 7, 10, 23, 30), price: "$15", venue: venue).tap do |record|
      record.links = [existing_link]
    end
  end

  it "prefills attributes and associations from the show" do
    form = described_class.new(show: show)

    expect(form).to have_attributes(
      date: "2026-07-10", time: "19:30", price: "$15",
      venue_id: venue.id.to_s, link_ids: [existing_link.id.to_s]
    )
  end

  it "updates fields and replaces existing associations" do
    form = described_class.new(
      show: show,
      date: "2026-08-12", time: "20:15", price: "$20",
      venue_id: replacement_venue.id.to_s,
      link_ids: [replacement_link.id.to_s]
    )

    expect(form.save).to be(true)
    expect(show.reload).to have_attributes(
      time: Time.utc(2026, 8, 13, 0, 15), price: "$20", venue: replacement_venue
    )
    expect(show.links).to contain_exactly(replacement_link)
  end

  it "creates a new venue and link while editing" do
    form = described_class.new(
      show: show,
      date: "2026-07-10", time: "19:30", price: "$18",
      new_venue: { name: "Elsewhere", city: "Brooklyn", state: "NY", map_url: "https://maps.example/elsewhere" },
      new_links: { "0" => { name: "Tickets", url: "https://example.com/tickets" } }
    )

    expect { form.save }.to change(Venue, :count).by(1).and change(Link, :count).by(1)
    expect(show.reload.venue.name).to eq("Elsewhere")
    expect(show.links.pluck(:name)).to contain_exactly("Tickets")
  end
end
```

- [ ] **Step 2: Record the intended red check**

Intended command outside this environment:

```bash
script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb
```

Expected: failures because `Admin::ShowForm#initialize` treats `show` as an unknown attribute and has no update mode. Do not run this command in the current workspace.

- [ ] **Step 3: Implement initialization and transactional update**

Change initialization to extract `show`, prefill only when no submitted attributes are present, and normalize IDs as strings:

```ruby
def initialize(attributes = {})
  attributes = attributes.to_h
  @show = attributes.delete(:show) || attributes.delete("show")
  attributes = attributes.presence || attributes_from_show
  super(attributes)
  self.link_ids ||= []
  self.new_venue ||= {}
  self.new_links ||= {}
end

def attributes_from_show
  return {} unless show

  eastern_time = show.time.in_time_zone("Eastern Time (US & Canada)")
  {
    date: eastern_time.to_date.iso8601,
    time: eastern_time.strftime("%H:%M"),
    price: show.price,
    venue_id: show.venue_id&.to_s,
    link_ids: show.link_ids.map(&:to_s)
  }
end
```

Replace unconditional creation in `save` with a helper that updates or creates:

```ruby
ApplicationRecord.transaction do
  venue = existing_venue || create_new_venue
  @show ||= Show.new
  @show.update!(time: parsed_time, price: price, venue: venue)
  @show.links = existing_links
  normalized_new_links.each { |link_attributes| @show.links << Link.create!(link_attributes) }
end
```

Keep the current `RecordInvalid` rescue so all record changes roll back and errors attach to the form.

- [ ] **Step 4: Perform static form checks**

Run:

```bash
rg -n "def initialize|attributes_from_show|@show \|\|= Show.new|@show.update!" app/forms/admin/show_form.rb
git diff --check
```

Expected: all four update-mode elements are present and `git diff --check` exits zero.

- [ ] **Step 5: Commit**

```bash
git add app/forms/admin/show_form.rb spec/forms/admin/show_form_spec.rb
git commit -m "Add show form update mode"
```

### Task 2: Admin Edit and Update Endpoints

**Files:**
- Modify: `config/routes.rb`
- Modify: `spec/requests/admin_shows_spec.rb`
- Modify: `app/controllers/admin/shows_controller.rb`

- [ ] **Step 1: Write failing request specs**

Add `GET /admin/shows/:id/edit` and `PATCH /admin/shows/:id` examples. Cover signed-out redirect and non-admin 403 for both verbs, then add these admin behaviors:

```ruby
describe "GET /admin/shows/:id/edit" do
  it "renders a prefilled edit form for an admin" do
    admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
    venue = Venue.create!(name: "Union Hall")
    show = Show.create!(time: Time.utc(2026, 7, 10, 23, 30), price: "$15", venue: venue)
    sign_in(admin)

    get edit_admin_show_path(show)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Edit Show", "2026-07-10", "19:30", "$15", "Union Hall")
  end
end

describe "PATCH /admin/shows/:id" do
  it "updates a show and redirects home" do
    admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
    show = Show.create!(time: Time.utc(2026, 7, 10, 23, 30), price: "$15")
    sign_in(admin)

    patch admin_show_path(show), params: {
      admin_show_form: { date: "2026-08-12", time: "20:15", price: "$20" }
    }

    expect(response).to redirect_to(root_path)
    expect(show.reload).to have_attributes(time: Time.utc(2026, 8, 13, 0, 15), price: "$20")
  end

  it "renders the edit page with submitted values when invalid" do
    admin = User.create!(email_address: "admin@example.com", password: "password", admin: true)
    show = Show.create!(time: Time.utc(2026, 7, 10, 23, 30), price: "$15")
    sign_in(admin)

    patch admin_show_path(show), params: {
      admin_show_form: { date: "2026-08-12", time: "20:15", price: "" }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Price can&#39;t be blank", "2026-08-12")
    expect(show.reload.price).to eq("$15")
  end
end
```

The successful update example should additionally submit `new_venue` and `new_links`, then assert the new records are associated.

- [ ] **Step 2: Record the intended red check**

Intended command outside this environment:

```bash
script/rails5 bundle exec rspec spec/requests/admin_shows_spec.rb
```

Expected: route helper/action failures. Do not run this command in the current workspace.

- [ ] **Step 3: Add RESTful routes and controller actions**

Change the route to:

```ruby
resources :shows, only: [:create, :edit, :update]
```

Add controller actions and focused preparation helpers:

```ruby
def edit
  @show = Show.includes(:links).find(params[:id])
  @show_form = Admin::ShowForm.new(show: @show)
  prepare_choices
end

def update
  @show = Show.includes(:links).find(params[:id])
  @show_form = Admin::ShowForm.new(show: @show, **show_form_params.to_h.symbolize_keys)

  if @show_form.save
    redirect_to root_path, notice: "Show updated."
  else
    prepare_choices
    render :edit, status: :unprocessable_content
  end
end

def prepare_choices
  @venues = Venue.order(:name, :city)
  @links = Link.order(:name)
end
```

Keep `before_action :require_admin`, the existing create action, and the existing strong-parameter list unchanged.

- [ ] **Step 4: Perform static endpoint checks**

Run:

```bash
rg -n "resources :shows|def edit|def update|Show updated|render :edit|def prepare_choices" config/routes.rb app/controllers/admin/shows_controller.rb
git diff --check
```

Expected: edit/update routes and action branches are present and the diff check exits zero.

- [ ] **Step 5: Commit**

```bash
git add config/routes.rb app/controllers/admin/shows_controller.rb spec/requests/admin_shows_spec.rb
git commit -m "Add admin show edit endpoints"
```

### Task 3: Shared Edit Form and Admin-Only Table Column

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/views/pages/home.html.erb`
- Modify: `app/views/pages/_admin_show_form.html.erb`
- Create: `app/views/admin/shows/edit.html.erb`
- Modify: `app/assets/stylesheets/application.css`

- [ ] **Step 1: Write failing view specs for conditional Edit controls**

Add one non-admin example and one admin example using a persisted Show so polymorphic route generation has an ID:

```ruby
it "does not render an Edit column for non-admins" do
  show = Show.create!(time: Time.utc(2026, 7, 10, 23, 30), price: "$15")
  assign(:shows, [show])

  render template: "pages/home"

  expect(rendered).not_to include("Edit Show")
  expect(Nokogiri::HTML.fragment(rendered).css(".shows-table__edit")).to be_empty
end

it "renders a separate Edit cell for each Show when admin" do
  allow(view).to receive(:admin?).and_return(true)
  show = Show.create!(time: Time.utc(2026, 7, 10, 23, 30), price: "$15")
  assign(:shows, [show])
  assign(:show_form, Admin::ShowForm.new)
  assign(:venues, [])
  assign(:links, [])

  render template: "pages/home"

  cell = Nokogiri::HTML.fragment(rendered).at_css(".shows-table__edit")
  expect(cell.at_css("a")["href"]).to eq(edit_admin_show_path(show))
  expect(cell.at_css("a").text).to eq("Edit")
end
```

- [ ] **Step 2: Record the intended red check**

Intended command outside this environment:

```bash
script/rails5 bundle exec rspec spec/views/pages/home.html.erb_spec.rb spec/requests/admin_shows_spec.rb
```

Expected: missing Edit cell and missing edit template failures. Do not run this command in the current workspace.

- [ ] **Step 3: Generalize the form partial**

Pass locals from the home page:

```erb
<%= render "pages/admin_show_form",
      form: @show_form,
      venues: @venues,
      links: @links,
      form_url: admin_shows_path,
      title: "Add a Show",
      submit_label: "Create Show",
      error_action: "created" if admin? %>
```

In the partial, replace hard-coded create strings and URL with the locals:

```erb
<h3 id="admin-show-form-title"><%= title %></h3>
<h4><%= pluralize(form.errors.count, "error") %> prevented this Show from being <%= error_action %>:</h4>
<%= form_with model: form, url: form_url, class: "admin-show-form__form" do |show_fields| %>
  <!-- retain all existing fields unchanged -->
  <%= show_fields.submit submit_label, class: "form-button form-button--primary" %>
<% end %>
```

- [ ] **Step 4: Add the edit page and table cell**

Create the edit page:

```erb
<main class="admin-edit-page">
  <%= link_to "Back to Shows", root_path(anchor: "shows"), class: "admin-edit-page__back" %>
  <%= render "pages/admin_show_form",
        form: @show_form,
        venues: @venues,
        links: @links,
        form_url: admin_show_path(@show),
        title: "Edit Show",
        submit_label: "Update Show",
        error_action: "updated" %>
</main>
```

Append this cell after the Links cell in every table row:

```erb
<% if admin? %>
  <td class="shows-table__edit">
    <%= link_to "Edit", edit_admin_show_path(show), class: "form-button form-button--secondary" %>
  </td>
<% end %>
```

Add focused layout rules:

```css
.admin-edit-page {
  box-sizing: border-box;
  margin: 0 auto;
  max-width: 72rem;
  min-height: 100vh;
  padding: 2rem;
}

.admin-edit-page__back,
.shows-table__edit a {
  display: inline-block;
}
```

- [ ] **Step 5: Perform static template and diff checks**

Run:

```bash
rg -n "form_url|submit_label|error_action|Edit Show|edit_admin_show_path|shows-table__edit" app/views app/assets/stylesheets/application.css spec/views/pages/home.html.erb_spec.rb
git diff --check
git status --short
```

Expected: both form call sites provide every required local, the admin-only Edit cell is present, the new template is tracked, and the diff check exits zero.

- [ ] **Step 6: Commit**

```bash
git add app/views/pages/home.html.erb app/views/pages/_admin_show_form.html.erb app/views/admin/shows/edit.html.erb app/assets/stylesheets/application.css spec/views/pages/home.html.erb_spec.rb
git commit -m "Add admin show editing interface"
```

### Task 4: Final Static Review

**Files:**
- Review all files changed by Tasks 1-3.

- [ ] **Step 1: Inspect the complete feature diff**

```bash
git diff HEAD~3 -- app/forms/admin/show_form.rb app/controllers/admin/shows_controller.rb config/routes.rb app/views/pages app/views/admin/shows app/assets/stylesheets/application.css spec/forms/admin/show_form_spec.rb spec/requests/admin_shows_spec.rb spec/views/pages/home.html.erb_spec.rb
```

Check every design requirement against the diff: admin-only column, separate page, prefilled fields, existing/new Venue and Link support, transactional update, authorization, 422 redisplay, and root redirect.

- [ ] **Step 2: Scan for structural mistakes and placeholders**

```bash
git diff --check
rg -n "TBD|TODO|PLACEHOLDER|admin_show_form" app spec config/routes.rb
```

Expected: `git diff --check` exits zero; no new placeholders are present; every form uses the `admin_show_form` parameter key expected by strong parameters.

- [ ] **Step 3: Document unavailable runtime verification**

Do not run Ruby tooling. Report the exact RSpec command that should be run in a functional environment:

```bash
script/rails5 bundle exec rspec spec/forms/admin/show_form_spec.rb spec/requests/admin_shows_spec.rb spec/views/pages/home.html.erb_spec.rb
```

State explicitly that runtime test results are unknown until that command can execute.
