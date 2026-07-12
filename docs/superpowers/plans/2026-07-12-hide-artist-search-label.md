# Hide Artist Search Label Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the visible `Search artists` text from the admin new/edit show form while preserving the search field's accessible name and filtering behavior.

**Architecture:** The shared form partial will replace the visible `<label>` with `aria-label="Search artists"` on the search input. Existing view and browser specs will verify the invisible accessible naming contract and unchanged Stimulus behavior.

**Tech Stack:** Rails 8 ERB helpers, Stimulus 3, RSpec view/system specs, Nokogiri, Selenium with headless Chrome

---

## File structure

- Modify `spec/views/pages/home.html.erb_spec.rb` to reject a visible search label and require the input's `aria-label`.
- Modify `spec/system/admin_show_artist_search_spec.rb` to locate the search input by its accessible attribute while continuing to exercise filtering.
- Modify `app/views/pages/_admin_show_form.html.erb` to remove the visible label and add `aria-label` to the input.

### Task 1: Remove the visible search label accessibly

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb:95-110`
- Modify: `spec/system/admin_show_artist_search_spec.rb:17-35`
- Modify: `app/views/pages/_admin_show_form.html.erb:71-81`

- [ ] **Step 1: Write failing view expectations**

Replace the existing search-input expectation with:

```ruby
search_input = artist_field.at_css('input[type="search"][data-artist-select-target="search"]')
expect(search_input).to be_present
expect(search_input["aria-label"]).to eq("Search artists")
expect(artist_field.at_css('label[for="artist_search"]')).not_to be_present
```

- [ ] **Step 2: Run the view spec to verify RED**

Run:

```bash
.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb
```

Expected: FAIL because the input has no `aria-label` and the visible `<label for="artist_search">Search artists</label>` is present.

- [ ] **Step 3: Update the browser spec's search-field lookup**

Inside the system example, define:

```ruby
search_input = find('input[aria-label="Search artists"]')
```

Replace each `fill_in "Search artists", with: value` call with:

```ruby
search_input.fill_in(with: value)
```

using `"beta"`, `"missing"`, and `""` for the three existing calls.

- [ ] **Step 4: Implement the accessible input without visible text**

Remove:

```erb
<%= label_tag :artist_search, "Search artists" %>
```

and add `aria: { label: "Search artists" }` to the search helper:

```erb
<%= search_field_tag :artist_search, nil,
      autocomplete: "off",
      aria: { label: "Search artists" },
      data: {
        action: "input->artist-select#filter",
        artist_select_target: "search"
      } %>
```

- [ ] **Step 5: Run focused specs to verify GREEN**

Run:

```bash
.local/bin/bundle exec rspec spec/views/pages/home.html.erb_spec.rb spec/system/admin_show_artist_search_spec.rb
```

Expected: PASS.

- [ ] **Step 6: Run the complete checks**

Run:

```bash
.local/bin/bundle exec rspec
.local/bin/bundle exec rubocop
```

Expected: RSpec exits with zero failures and RuboCop reports no offenses.

- [ ] **Step 7: Commit**

```bash
git add app/views/pages/_admin_show_form.html.erb spec/views/pages/home.html.erb_spec.rb spec/system/admin_show_artist_search_spec.rb
git commit -m "Hide artist search label"
```
