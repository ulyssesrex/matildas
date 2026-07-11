# High-Contrast Site Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply uppercase Helvetica and a minimalist, high-contrast black-and-white visual system to every active Rails page.

**Architecture:** Centralize presentation in the existing application stylesheet so the layout, homepage, show table, and forms inherit one visual system. Remove the admin login's inline semantic colors so feedback is styled by reusable CSS classes while preserving all content and behavior.

**Tech Stack:** Rails 8.1, ERB, CSS, RSpec, RuboCop

---

### Task 1: Make Admin Login Feedback Styleable

**Files:**
- Modify: `spec/views/admin/sessions/new.html.erb_spec.rb`
- Modify: `app/views/admin/sessions/new.html.erb`

- [ ] **Step 1: Write the failing feedback markup spec**

Add this example inside the existing view spec:

```ruby
it "renders monochrome-compatible feedback without inline colors" do
  flash[:alert] = "Invalid credentials"
  flash[:notice] = "Signed out"

  render template: "admin/sessions/new"

  fragment = Nokogiri::HTML.fragment(rendered)
  messages = fragment.css(".flash")

  expect(messages.map(&:text)).to contain_exactly("Invalid credentials", "Signed out")
  expect(messages.map { |message| message["class"] }).to contain_exactly(
    "flash flash--alert",
    "flash flash--notice"
  )
  expect(rendered).not_to include("style=")
end
```

- [ ] **Step 2: Run the view spec and verify it fails**

Run: `script/rails5 bundle exec rspec spec/views/admin/sessions/new.html.erb_spec.rb`

Expected: FAIL because the messages have inline red and green styles and no `flash` classes.

- [ ] **Step 3: Replace inline feedback styles with shared classes**

Replace the first two lines of `app/views/admin/sessions/new.html.erb` with:

```erb
<%= tag.div(flash[:alert], class: "flash flash--alert", role: "alert") if flash[:alert] %>
<%= tag.div(flash[:notice], class: "flash flash--notice", role: "status") if flash[:notice] %>
```

- [ ] **Step 4: Run the focused view spec**

Run: `script/rails5 bundle exec rspec spec/views/admin/sessions/new.html.erb_spec.rb`

Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit the semantic feedback change**

```bash
git add app/views/admin/sessions/new.html.erb spec/views/admin/sessions/new.html.erb_spec.rb
git commit -m "Use shared styles for login feedback"
```

### Task 2: Apply the Global High-Contrast Visual System

**Files:**
- Modify: `app/assets/stylesheets/application.css`

- [ ] **Step 1: Add the global typography, palette, and interaction rules**

Extend `:root` and the base element rules to establish shared tokens and presentation-only uppercase text:

```css
:root {
  --color-black: #000;
  --color-white: #fff;
  --site-nav-height: 4.5rem;
}

html {
  background: var(--color-black);
  color: var(--color-white);
  font-family: Helvetica, Arial, sans-serif;
  scroll-behavior: smooth;
  text-transform: uppercase;
}

body {
  background: var(--color-black);
  color: var(--color-white);
  margin: 0;
}

a {
  color: inherit;
}

:focus-visible {
  outline: 2px solid var(--color-white);
  outline-offset: 3px;
}
```

- [ ] **Step 2: Convert navigation, table, and feedback surfaces to pure black and white**

Update the existing selectors to use `var(--color-black)` and `var(--color-white)`. Remove component-level Arial declarations. Give `.site-nav` a white bottom border, give all `.shows-table td` white borders, and make `.flash` a white-bordered black surface:

```css
.site-nav {
  background: var(--color-black);
  border-bottom: 1px solid var(--color-white);
}

.site-nav__link {
  color: var(--color-white);
}

.shows-table {
  margin-top: 1rem;
  width: 100%;
}

.shows-table td {
  border: 1px solid var(--color-white);
  padding: 0.75rem;
  text-align: left;
}

.flash {
  background: var(--color-black);
  border: 1px solid var(--color-white);
  color: var(--color-white);
  font-weight: 700;
  padding: 0.75rem 1rem;
}
```

Keep `border-collapse: collapse` on `.shows-table` and preserve its responsive wrapper.

- [ ] **Step 3: Convert forms, controls, hints, and errors to monochrome**

Use white rules for `.admin-show-form`, `.admin-show-form__panel`, and `.form-divider`. Make the divider label black, and apply the shared control treatment:

```css
.form-field input[type="date"],
.form-field input[type="email"],
.form-field input[type="password"],
.form-field input[type="time"],
.form-field input[type="text"],
.form-field input[type="url"],
.form-field select,
input[type="email"],
input[type="password"] {
  background: var(--color-black);
  border: 1px solid var(--color-white);
  border-radius: 0;
  box-sizing: border-box;
  color: var(--color-white);
  font: inherit;
  max-width: 100%;
  padding: 0.55rem;
  text-transform: uppercase;
  width: 100%;
}

.form-button,
input[type="submit"] {
  border: 1px solid var(--color-white);
  border-radius: 0;
  cursor: pointer;
  font: inherit;
  padding: 0.6rem 0.9rem;
  text-transform: uppercase;
}

.form-button--primary,
input[type="submit"] {
  background: var(--color-white);
  color: var(--color-black);
  font-weight: 700;
}

.form-button--secondary {
  background: var(--color-black);
  color: var(--color-white);
}

.form-errors {
  background: var(--color-black);
  border: 1px solid var(--color-white);
  color: var(--color-white);
}

.field-error,
.form-hint {
  color: var(--color-white);
}
```

Retain the existing layout, spacing, grid, and responsive declarations. Delete rules superseded by these declarations so no gray, red, or tinted surface values remain.

- [ ] **Step 4: Verify the stylesheet contains only the approved palette**

Run: `rg -n '#(111|555|760000|a40000|b7b7b7|d8d8d8)|fff2f2|Arial, sans-serif' app/assets/stylesheets/application.css`

Expected: no output. The only font stack is `Helvetica, Arial, sans-serif`, and palette declarations resolve through the black and white variables.

- [ ] **Step 5: Run focused view and request coverage**

Run: `script/rails5 bundle exec rspec spec/views/admin/sessions/new.html.erb_spec.rb spec/views/pages/home.html.erb_spec.rb spec/requests/pages_spec.rb spec/requests/admin_sessions_spec.rb`

Expected: all examples pass with 0 failures.

- [ ] **Step 6: Commit the visual system**

```bash
git add app/assets/stylesheets/application.css
git commit -m "Apply high contrast site styling"
```

### Task 3: Run Full Verification

**Files:**
- Verify only

- [ ] **Step 1: Run the full test suite**

Run: `script/rails5 bundle exec rspec`

Expected: all examples pass with 0 failures.

- [ ] **Step 2: Run RuboCop**

Run: `script/rails5 bundle exec rubocop`

Expected: no offenses.

- [ ] **Step 3: Check the final diff**

Run: `git diff --check HEAD~2..HEAD`

Expected: no output and exit status 0.
