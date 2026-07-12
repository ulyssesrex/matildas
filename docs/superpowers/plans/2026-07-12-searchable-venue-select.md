# Searchable Venue Select Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the admin Show form's single Venue selector searchable and show each Venue's location in its option text.

**Architecture:** Reuse the existing `artist-select` Stimulus controller with a scalar Venue select. Build display labels in the shared form partial from each Venue's name, city, and state, so filtering naturally searches all displayed text without persistence changes.

**Tech Stack:** Rails ERB, Stimulus, RSpec, Capybara/Selenium

---

### Task 1: Specify the Venue selector markup

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/views/pages/_admin_show_form.html.erb`

- [ ] **Step 1: Write the failing view spec**

Add assertions that the Venue field uses `data-controller="artist-select"`, contains an unlabeled search input with `aria-label="Search venues"`, and renders a `select[name="admin_show_form[venue_id]"]` without `multiple`. Assert its option text is `Union Hall (Brooklyn, NY)` and its selected value remains the Venue ID.

- [ ] **Step 2: Run the view spec to verify it fails**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: FAIL because the Venue field has no search input/controller target and its option lacks location text.

- [ ] **Step 3: Implement the searchable single-select**

In the Venue field, add the existing controller, a search input wired to `input->artist-select#filter`, and a single select wired to the controller's `select` target. Construct each option label as the Venue name plus nonblank city/state joined with `, ` inside parentheses; omit parentheses when both are blank. Preserve the `Existing venue` visible label and do not add `multiple` or a second visible label.

- [ ] **Step 4: Run the view spec to verify it passes**

Run: `.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: PASS.

### Task 2: Specify browser filtering behavior

**Files:**
- Create: `spec/system/admin_show_venue_search_spec.rb`

- [ ] **Step 1: Write the failing system spec**

Create two Venues with distinct names and locations. Log in as an admin, select one Venue, search for the other Venue's city, and assert both the matching and selected options remain visible. Search for a missing value and assert only the selected option remains visible, then clear the search and assert all options are visible again.

- [ ] **Step 2: Run the system spec to verify it fails**

Run: `.local/bin/bundle exec rspec spec/system/admin_show_venue_search_spec.rb`

Expected: FAIL before the searchable Venue markup exists.

- [ ] **Step 3: Run focused regression specs**

Run: `.local/bin/bundle exec rspec spec/system/admin_show_venue_search_spec.rb spec/system/admin_show_artist_search_spec.rb spec/requests/admin_shows_spec.rb spec/forms/admin/show_form_spec.rb spec/views/pages/home.html.erb_spec.rb`

Expected: PASS.

### Task 3: Verify and commit

**Files:**
- Modify: all files listed above

- [ ] **Step 1: Run style checks for changed Ruby/ERB-related files**

Run: `.local/bin/bundle exec rubocop spec/system/admin_show_venue_search_spec.rb spec/views/pages/home.html.erb_spec.rb`

Expected: PASS with no offenses.

- [ ] **Step 2: Check the final diff**

Run: `git diff --check`

Expected: no output.

- [ ] **Step 3: Commit to main**

Stage the design, plan, implementation, and tests, then commit with message `Add searchable venue select`.
