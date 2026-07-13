# Navigation Link Heading Size Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all primary navigation links use the same explicit font size as the home-page section headings.

**Architecture:** Keep typography in the existing application stylesheet. Introduce one root custom property and consume it from both the navigation-link and home-section-heading selectors so their size cannot drift.

**Tech Stack:** Rails 8.1, CSS custom properties, RSpec, RuboCop

---

## File Structure

- Create `spec/stylesheets/application_spec.rb`: verify the shared typography contract in the compiled source stylesheet.
- Modify `app/assets/stylesheets/application.css`: define and apply the shared heading font-size property.

### Task 1: Share the Body Heading Font Size

**Files:**
- Create: `spec/stylesheets/application_spec.rb`
- Modify: `app/assets/stylesheets/application.css:12-66`

- [ ] **Step 1: Write the failing stylesheet spec**

Create `spec/stylesheets/application_spec.rb` with:

```ruby
require "rails_helper"

RSpec.describe "Application stylesheet" do
  subject(:stylesheet) { Rails.root.join("app/assets/stylesheets/application.css").read }

  it "uses the body heading size for home section headings and navigation links" do
    expect(stylesheet).to match(/--body-heading-font-size:\s*1\.5rem;/)
    expect(stylesheet).to match(/\.home-section h2\s*\{[^}]*font-size:\s*var\(--body-heading-font-size\);/m)
    expect(stylesheet).to match(/\.site-nav__link\s*\{[^}]*font-size:\s*var\(--body-heading-font-size\);/m)
  end
end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `.local/bin/bundle exec rspec spec/stylesheets/application_spec.rb`

Expected: one failing example because `--body-heading-font-size` is not defined or consumed yet.

- [ ] **Step 3: Implement the shared font size**

Add the property to the existing `:root` rule in `app/assets/stylesheets/application.css`:

```css
  --body-heading-font-size: 1.5rem;
```

Add this rule after `.site-nav__brand`:

```css
.home-section h2 {
  font-size: var(--body-heading-font-size);
}
```

Replace the `.site-nav__link` font-size declaration with:

```css
  font-size: var(--body-heading-font-size);
```

- [ ] **Step 4: Run focused verification**

Run: `.local/bin/bundle exec rspec spec/stylesheets/application_spec.rb spec/requests/pages_spec.rb`

Expected: all stylesheet and page request examples pass.

- [ ] **Step 5: Run style verification**

Run: `.local/bin/bundle exec rubocop spec/stylesheets/application_spec.rb`

Expected: no offenses.

- [ ] **Step 6: Inspect and commit the implementation**

Run: `git diff --check && git diff -- app/assets/stylesheets/application.css spec/stylesheets/application_spec.rb`

Expected: no whitespace errors and a diff limited to the shared property, its two consumers, and the focused spec.

Then run:

```bash
git add app/assets/stylesheets/application.css spec/stylesheets/application_spec.rb
git commit -m "Increase navigation link size"
```
