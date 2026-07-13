# Logo Favicon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Use the existing `logo.png` asset as the favicon and Apple touch icon on every page rendered by the application layout.

**Architecture:** Add request-level coverage for the icon metadata emitted by the shared layout, then replace the static public icon links with Rails favicon helpers. Both declarations resolve the same Propshaft-managed image so deployed pages receive the digest-stamped asset URL.

**Tech Stack:** Rails 8 views, Propshaft, RSpec request specs, Nokogiri

---

### Task 1: Render the logo as application icon metadata

**Files:**
- Modify: `spec/requests/pages_spec.rb`
- Modify: `app/views/layouts/application.html.erb`

- [ ] **Step 1: Write the failing request spec**

Add this example inside `describe "GET /"` in `spec/requests/pages_spec.rb`:

```ruby
it "uses the logo asset as the favicon and Apple touch icon" do
  get root_path

  document = Nokogiri::HTML(response.body)
  logo_asset_path = ActionController::Base.helpers.asset_path("logo.png")
  favicon = document.at_css('head link[rel="icon"][type="image/png"]')
  apple_touch_icon = document.at_css('head link[rel="apple-touch-icon"]')

  expect(favicon["href"]).to eq(logo_asset_path)
  expect(apple_touch_icon["href"]).to eq(logo_asset_path)
  expect(document.css('head link[rel="icon"]').length).to eq(1)
end
```

- [ ] **Step 2: Run the focused spec to verify it fails**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb
```

Expected: FAIL because the favicon and Apple touch icon still point to `/icon.png`, and the layout still emits a second SVG favicon.

- [ ] **Step 3: Replace the static icon declarations with asset helpers**

Replace the three existing icon links in `app/views/layouts/application.html.erb` with:

```erb
<%= favicon_link_tag "logo.png", type: "image/png" %>
<%= favicon_link_tag "logo.png", rel: "apple-touch-icon", type: "image/png" %>
```

- [ ] **Step 4: Run the focused spec to verify it passes**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb
```

Expected: all examples pass.

- [ ] **Step 5: Run the full verification suite**

Run:

```bash
.local/bin/bundle exec rspec
.local/bin/bundle exec rubocop
```

Expected: the complete RSpec suite and RuboCop both exit successfully with no failures or offenses.

- [ ] **Step 6: Commit the implementation**

```bash
git add spec/requests/pages_spec.rb app/views/layouts/application.html.erb
git commit -m "Use logo as favicon"
```
