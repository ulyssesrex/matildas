# Responsive Navigation Separator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a one-pixel white separator that is full-height and vertical in the single-row navigation layout, then full-width and horizontal in the stacked navigation layout.

**Architecture:** Wrap the three section links in a dedicated flex group and make the brand and link group responsible for the navigation's padding. The link group owns the separator border, switching from a left border to a top border at the existing `38rem` breakpoint; the mobile scroll offset gains the separator's extra pixel.

**Tech Stack:** Rails ERB, CSS flexbox and media queries, RSpec request and stylesheet specs

---

## File Structure

- Modify `app/views/pages/home.html.erb`: group the Music, Shows, and Misc links as the second responsive navigation region.
- Modify `app/assets/stylesheets/application.css`: lay out the two navigation regions, draw the responsive separator, and keep the mobile sticky-header offset accurate.
- Modify `spec/requests/pages_spec.rb`: verify the link group appears directly after the brand and contains all three section links.
- Modify `spec/stylesheets/application_spec.rb`: verify both separator orientations and the updated mobile height.

### Task 1: Add the responsive navigation regions and separator

**Files:**
- Modify: `spec/requests/pages_spec.rb:15-28`
- Modify: `spec/stylesheets/application_spec.rb:6-16`
- Modify: `app/views/pages/home.html.erb:1-6`
- Modify: `app/assets/stylesheets/application.css:43-77,282-295`

- [ ] **Step 1: Write the failing request spec**

Add a structural expectation to `renders navigation links to each home page section` immediately after the existing brand expectation:

```ruby
expect(response.body).to match(
  %r{<a class="site-nav__link site-nav__brand" href="#top">THE MOON RINGERS</a>\s*<div class="site-nav__links">\s*<a class="site-nav__link" href="#music">Music</a>\s*<a class="site-nav__link" href="#shows">Shows</a>\s*<a class="site-nav__link" href="#misc">Misc</a>\s*</div>}
)
```

- [ ] **Step 2: Run the focused request spec to verify it fails**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb:15
```

Expected: FAIL because the response has no `.site-nav__links` wrapper.

- [ ] **Step 3: Write the failing stylesheet specs**

Replace the current mobile scroll-offset example in `spec/stylesheets/application_spec.rb` and add a separator example so the bottom of the file reads:

```ruby
it "draws a full-height separator before the navigation link group" do
  expect(stylesheet).to match(
    /\.site-nav__links\s*\{[^}]*border-left:\s*1px solid var\(--color-white\);/m
  )
end

it "uses a full-width separator and accurate scroll offset for the stacked navigation" do
  expect(stylesheet).to match(
    /@media \(max-width: 38rem\)\s*\{.*?:root\s*\{[^}]*--site-nav-height:\s*calc\(5\.5rem \+ 2px\);/m
  )
  expect(stylesheet).to match(
    /@media \(max-width: 38rem\)\s*\{.*?\.site-nav__links\s*\{[^}]*border-left:\s*0;[^}]*border-top:\s*1px solid var\(--color-white\);/m
  )
end
```

- [ ] **Step 4: Run the focused stylesheet specs to verify they fail**

Run:

```bash
.local/bin/bundle exec rspec spec/stylesheets/application_spec.rb
```

Expected: 2 failures because `.site-nav__links` has no border rules and the mobile offset still accounts for only one border pixel.

- [ ] **Step 5: Group the section links in the view**

Replace the navigation markup at the top of `app/views/pages/home.html.erb` with:

```erb
<nav class="site-nav" aria-label="Primary navigation">
  <a class="site-nav__link site-nav__brand" href="#top">THE MOON RINGERS</a>
  <div class="site-nav__links">
    <a class="site-nav__link" href="#music">Music</a>
    <a class="site-nav__link" href="#shows">Shows</a>
    <a class="site-nav__link" href="#misc">Misc</a>
  </div>
</nav>
```

- [ ] **Step 6: Implement the wide navigation layout and vertical separator**

Replace the existing `.site-nav` rule with:

```css
.site-nav {
  align-items: stretch;
  background: var(--color-black);
  border-bottom: 1px solid var(--color-white);
  box-sizing: border-box;
  display: flex;
  flex-wrap: wrap;
  gap: 0;
  justify-content: center;
  min-height: var(--site-nav-height);
  padding: 0;
  position: sticky;
  top: 0;
  z-index: 10;
}
```

Replace the existing `.site-nav__brand` rule with these navigation-region rules:

```css
.site-nav__brand,
.site-nav__links {
  box-sizing: border-box;
  padding: 1rem;
}

.site-nav__brand {
  align-items: center;
  display: flex;
  flex: 1;
}

.site-nav__links {
  align-items: center;
  border-left: 1px solid var(--color-white);
  display: flex;
  gap: 1rem;
  justify-content: center;
}
```

The group stretches with the navigation container, so its left border covers the complete header height while preserving the existing `1rem` text inset.

- [ ] **Step 7: Implement the stacked layout and horizontal separator**

Replace the existing `@media (max-width: 38rem)` block with:

```css
@media (max-width: 38rem) {
  :root {
    --site-nav-height: calc(5.5rem + 2px);
  }

  .site-nav {
    justify-content: flex-start;
  }

  .site-nav__brand,
  .site-nav__links {
    flex-basis: 100%;
    padding-block: 0.625rem;
  }

  .site-nav__links {
    border-left: 0;
    border-top: 1px solid var(--color-white);
    justify-content: flex-start;
  }
}
```

Each row retains a `1.5rem` line box plus `1.25rem` total vertical padding. The two rows are therefore `5.5rem` tall, and the separator plus existing bottom border bring the sticky navigation height to `calc(5.5rem + 2px)`.

- [ ] **Step 8: Run both focused spec files**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb spec/stylesheets/application_spec.rb
```

Expected: all examples pass.

- [ ] **Step 9: Inspect the focused diff**

Run:

```bash
git diff --check
git diff -- app/views/pages/home.html.erb app/assets/stylesheets/application.css spec/requests/pages_spec.rb spec/stylesheets/application_spec.rb
```

Expected: `git diff --check` prints nothing. The diff contains only the navigation wrapper, responsive region styles, separator rules, height correction, and their specs.

- [ ] **Step 10: Commit the responsive separator**

```bash
git add app/views/pages/home.html.erb app/assets/stylesheets/application.css spec/requests/pages_spec.rb spec/stylesheets/application_spec.rb
git commit -m "Add responsive navigation separator"
```

### Task 2: Verify the completed change

**Files:**
- Verify: `app/views/pages/home.html.erb`
- Verify: `app/assets/stylesheets/application.css`
- Verify: `spec/requests/pages_spec.rb`
- Verify: `spec/stylesheets/application_spec.rb`

- [ ] **Step 1: Run the full RSpec suite**

Run:

```bash
.local/bin/bundle exec rspec
```

Expected: all examples pass with zero failures.

- [ ] **Step 2: Run RuboCop**

Run:

```bash
.local/bin/bundle exec rubocop
```

Expected: no offenses.

- [ ] **Step 3: Confirm the worktree is clean**

Run:

```bash
git status --short
```

Expected: no output.
