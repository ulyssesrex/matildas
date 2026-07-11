# Show Table Links Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render Venue map links and all Show Links in the public Shows table.

**Architecture:** Keep the behavior in the existing home-page ERB template because it is presentation-only. Extend the existing view spec to cover linked and plain Venue names, multiple Links in the row-final cell, and the empty Links state.

**Tech Stack:** Rails 8.1, ERB, RSpec

---

### Task 1: Render Venue and Show Links

**Files:**
- Modify: `spec/views/pages/home.html.erb_spec.rb`
- Modify: `app/views/pages/home.html.erb`

- [ ] **Step 1: Write failing view specs**

Create a Venue with `map_url`, two associated Links, and a Show. Assert the Venue name is an anchor with the exact Map URL and both Links are anchors in the last table cell. Add a second Show whose Venue has no Map URL and no Links; assert its Venue name is not wrapped in an anchor and its final cell is empty.

```ruby
venue = Venue.new(name: "Union Hall", city: "Brooklyn", state: "NY", map_url: "https://maps.example/union")
show = Show.new(time: Time.utc(2026, 7, 10, 23, 30), price: "$15", venue: venue)
show.links = [
  Link.new(name: "Tickets", url: "https://example.com/tickets"),
  Link.new(name: "Details", url: "https://example.com/details")
]

assign(:shows, [show])
render template: "pages/home"

expect(rendered).to include('<a href="https://maps.example/union">Union Hall</a>')
expect(rendered).to include('<a href="https://example.com/tickets">Tickets</a>')
expect(rendered).to include('<a href="https://example.com/details">Details</a>')
```

- [ ] **Step 2: Run the view spec and verify the red state**

Run: `bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: failures because Venue names are plain text and Show Links are not rendered.

- [ ] **Step 3: Implement the minimal ERB rendering**

Replace the Venue cell and append a final Links cell:

```erb
<td>
  <% if show.venue&.map_url.present? %>
    <%= link_to show.venue.name, show.venue.map_url %>
  <% else %>
    <%= show.venue&.name %>
  <% end %>
</td>
<td><%= [show.venue&.city, show.venue&.state].compact_blank.join(", ") %></td>
<td><%= show.price %></td>
<td class="shows-table__links">
  <% show.links.each do |link| %>
    <%= link_to link.name, link.url %>
  <% end %>
</td>
```

- [ ] **Step 4: Run the focused view spec**

Run: `bundle exec rspec spec/views/pages/home.html.erb_spec.rb`

Expected: zero failures.

- [ ] **Step 5: Run static verification**

Run: `git diff --check`

Expected: no output and exit status 0.

- [ ] **Step 6: Commit**

```bash
git add app/views/pages/home.html.erb spec/views/pages/home.html.erb_spec.rb
git commit -m "Render Venue and Show links in table"
```
