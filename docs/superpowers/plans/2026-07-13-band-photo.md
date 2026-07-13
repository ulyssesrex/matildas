# Band Photo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render the existing band photo directly above the Music section without changing the home page's general layout.

**Architecture:** Add the image to the existing home-page `<main>` with Rails' asset helper and a dedicated class. Keep the image at its intrinsic size when possible, while a minimal CSS rule preserves its aspect ratio and prevents narrow-screen overflow.

**Tech Stack:** Rails 8 views, Propshaft, CSS, RSpec request and stylesheet specs, Nokogiri

---

### Task 1: Add the responsive band photo above Music

**Files:**
- Modify: `spec/requests/pages_spec.rb`
- Modify: `spec/stylesheets/application_spec.rb`
- Modify: `app/views/pages/home.html.erb`
- Modify: `app/assets/stylesheets/application.css`

- [ ] **Step 1: Write the failing rendering and styling specs**

Add this example inside `describe "GET /"` in `spec/requests/pages_spec.rb`:

```ruby
it "renders the band photo immediately above the Music section" do
  get root_path

  document = Nokogiri::HTML(response.body)
  image = document.at_css("main#top > img.home-page__band-photo")
  music_section = document.at_css("main#top > section#music")

  expect(image).to be_present
  expect(image["src"]).to eq(ActionController::Base.helpers.asset_path("band_pic.jpg"))
  expect(image["alt"]).to eq("The Moon Ringers band")
  expect(music_section.previous_element).to eq(image)
end
```

Add this example to `spec/stylesheets/application_spec.rb`:

```ruby
it "keeps the band photo proportional and within the page width" do
  expect(stylesheet).to match(
    /\.home-page__band-photo\s*\{[^}]*display:\s*block;[^}]*height:\s*auto;[^}]*max-width:\s*100%;/m
  )
end
```

- [ ] **Step 2: Run the focused specs to verify they fail**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb spec/stylesheets/application_spec.rb
```

Expected: two failures because the home page does not render the image and the stylesheet does not define `.home-page__band-photo`.

- [ ] **Step 3: Render the image directly before Music**

In `app/views/pages/home.html.erb`, add this line after the flash-message loop and immediately before `<section id="music">`:

```erb
<%= image_tag "band_pic.jpg", class: "home-page__band-photo", alt: "The Moon Ringers band" %>
```

- [ ] **Step 4: Add the minimal responsive image rule**

In `app/assets/stylesheets/application.css`, add:

```css
.home-page__band-photo {
  display: block;
  height: auto;
  max-width: 100%;
}
```

- [ ] **Step 5: Run the focused specs to verify they pass**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb spec/stylesheets/application_spec.rb
```

Expected: all examples pass.

- [ ] **Step 6: Run the full verification suite**

Run:

```bash
.local/bin/bundle exec rspec
.local/bin/bundle exec rubocop
```

Expected: the complete RSpec suite and RuboCop both exit successfully with no failures or offenses.

- [ ] **Step 7: Commit the implementation**

```bash
git add spec/requests/pages_spec.rb spec/stylesheets/application_spec.rb app/views/pages/home.html.erb app/assets/stylesheets/application.css
git commit -m "Add band photo above music"
```
