# Bandcamp Music Players Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render four full-width Bandcamp players immediately below the Music heading in the requested album order.

**Architecture:** Store the stable iframe markup in a focused Rails partial owned by the home page and render it directly after the Music heading. Add dedicated responsive CSS matching the source presentation, with request and stylesheet specs covering structure, content, ordering, and layout.

**Tech Stack:** Rails 8 ERB views, Propshaft CSS, RSpec request and stylesheet specs, Nokogiri

---

### Task 1: Render the ordered Bandcamp player partial

**Files:**
- Create: `app/views/pages/_bandcamp_players.html.erb`
- Modify: `app/views/pages/home.html.erb`
- Test: `spec/requests/pages_spec.rb`

- [ ] **Step 1: Write the failing request spec**

Add this example inside `describe "GET /"` in `spec/requests/pages_spec.rb`:

```ruby
it "renders the Bandcamp players below Music in album order" do
  get root_path

  document = Nokogiri::HTML(response.body)
  music_section = document.at_css("main#top > section#music")
  heading = music_section.at_css("h2")
  player_container = music_section.at_css(".bandcamp-players")
  players = player_container.css(":scope > iframe.bandcamp-embed")

  expect(heading.text).to eq("Music")
  expect(heading.next_element).to eq(player_container)
  expect(players.map { |player| player["src"] }).to eq([
    "https://bandcamp.com/EmbeddedPlayer/album=3770867506/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/",
    "https://bandcamp.com/EmbeddedPlayer/album=1816368499/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/",
    "https://bandcamp.com/EmbeddedPlayer/album=3392802803/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/",
    "https://bandcamp.com/EmbeddedPlayer/album=3200630352/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/"
  ])
  expect(players.map { |player| player["title"] }).to eq([
    "Bandcamp player for Magic Mirror EP by The Matildas",
    "Bandcamp player for Dark Corners EP by The Matildas",
    "Bandcamp player for Ample Shortage (Demo) by The Matildas",
    "Bandcamp player for Noise That Works (Demo) by The Matildas"
  ])
  expect(players.map { |player| player["loading"] }).to all(eq("lazy"))
  expect(response.body).to include(
    'href="https://matildas.bandcamp.com/album/magic-mirror-ep"',
    'href="https://matildas.bandcamp.com/album/dark-corners-ep"',
    'href="https://matildas.bandcamp.com/album/ample-shortage-demo"',
    'href="https://matildas.bandcamp.com/album/noise-that-works-demo"'
  )
end
```

- [ ] **Step 2: Run the focused request spec to verify it fails**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb
```

Expected: FAIL because `.bandcamp-players` is absent from the Music section.

- [ ] **Step 3: Create the Bandcamp player partial**

Create `app/views/pages/_bandcamp_players.html.erb` with the stored iframe markup:

```erb
<div class="bandcamp-players">
  <iframe
    class="bandcamp-embed"
    src="https://bandcamp.com/EmbeddedPlayer/album=3770867506/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/"
    title="Bandcamp player for Magic Mirror EP by The Matildas"
    loading="lazy"
    seamless
  >
    <a href="https://matildas.bandcamp.com/album/magic-mirror-ep">Magic Mirror EP by The Matildas</a>
  </iframe>

  <iframe
    class="bandcamp-embed"
    src="https://bandcamp.com/EmbeddedPlayer/album=1816368499/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/"
    title="Bandcamp player for Dark Corners EP by The Matildas"
    loading="lazy"
    seamless
  >
    <a href="https://matildas.bandcamp.com/album/dark-corners-ep">Dark Corners EP by The Matildas</a>
  </iframe>

  <iframe
    class="bandcamp-embed"
    src="https://bandcamp.com/EmbeddedPlayer/album=3392802803/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/"
    title="Bandcamp player for Ample Shortage (Demo) by The Matildas"
    loading="lazy"
    seamless
  >
    <a href="https://matildas.bandcamp.com/album/ample-shortage-demo">Ample Shortage (Demo) by The Matildas</a>
  </iframe>

  <iframe
    class="bandcamp-embed"
    src="https://bandcamp.com/EmbeddedPlayer/album=3200630352/size=large/bgcol=ffffff/linkcol=333333/tracklist=false/artwork=small/transparent=true/"
    title="Bandcamp player for Noise That Works (Demo) by The Matildas"
    loading="lazy"
    seamless
  >
    <a href="https://matildas.bandcamp.com/album/noise-that-works-demo">Noise That Works (Demo) by The Matildas</a>
  </iframe>
</div>
```

- [ ] **Step 4: Render the partial directly after the Music heading**

Change the Music section in `app/views/pages/home.html.erb` to:

```erb
<section id="music" class="home-section">
  <h2>Music</h2>
  <%= render "pages/bandcamp_players" %>
</section>
```

- [ ] **Step 5: Run the focused request spec to verify it passes**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb
```

Expected: all examples pass.

- [ ] **Step 6: Commit the rendered players**

```bash
git add spec/requests/pages_spec.rb app/views/pages/home.html.erb app/views/pages/_bandcamp_players.html.erb
git commit -m "Add Bandcamp players to music section"
```

### Task 2: Style the players as a responsive vertical stack

**Files:**
- Modify: `app/assets/stylesheets/application.css`
- Test: `spec/stylesheets/application_spec.rb`

- [ ] **Step 1: Write the failing stylesheet specs**

Add these examples to `spec/stylesheets/application_spec.rb`:

```ruby
it "stacks full-width Bandcamp players with source spacing" do
  expect(stylesheet).to match(
    /\.bandcamp-embed\s*\{[^}]*display:\s*block;[^}]*width:\s*100%;[^}]*height:\s*140px;[^}]*border:\s*0;[^}]*background:\s*transparent;/m
  )
  expect(stylesheet).to match(
    /\.bandcamp-embed \+ \.bandcamp-embed\s*\{[^}]*margin-top:\s*24px;/m
  )
end

it "shortens Bandcamp players on narrow screens" do
  expect(stylesheet).to match(
    /@media \(max-width: 38rem\)\s*\{.*?\.bandcamp-embed\s*\{[^}]*height:\s*120px;/m
  )
end
```

- [ ] **Step 2: Run the focused stylesheet spec to verify it fails**

Run:

```bash
.local/bin/bundle exec rspec spec/stylesheets/application_spec.rb
```

Expected: two failures because the Bandcamp player rules are absent.

- [ ] **Step 3: Add the standard player styles**

Add this rule near the existing home-page styles in `app/assets/stylesheets/application.css`:

```css
.bandcamp-embed {
  display: block;
  width: 100%;
  height: 140px;
  border: 0;
  background: transparent;
}

.bandcamp-embed + .bandcamp-embed {
  margin-top: 24px;
}
```

- [ ] **Step 4: Add the narrow-screen height**

Add this rule inside the existing `@media (max-width: 38rem)` block:

```css
.bandcamp-embed {
  height: 120px;
}
```

- [ ] **Step 5: Run the focused stylesheet spec to verify it passes**

Run:

```bash
.local/bin/bundle exec rspec spec/stylesheets/application_spec.rb
```

Expected: all examples pass.

- [ ] **Step 6: Commit the responsive styles**

```bash
git add spec/stylesheets/application_spec.rb app/assets/stylesheets/application.css
git commit -m "Style Bandcamp player stack"
```

### Task 3: Verify the complete change

**Files:**
- Verify only; no file changes expected

- [ ] **Step 1: Run the focused feature specs together**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/pages_spec.rb spec/stylesheets/application_spec.rb
```

Expected: all examples pass.

- [ ] **Step 2: Run the full RSpec suite**

Run:

```bash
.local/bin/bundle exec rspec
```

Expected: all examples pass with zero failures.

- [ ] **Step 3: Run RuboCop**

Run:

```bash
.local/bin/bundle exec rubocop
```

Expected: all inspected files pass with no offenses.

- [ ] **Step 4: Confirm the worktree contains only the intended changes**

Run:

```bash
git status --short
git log -3 --oneline
```

Expected: the worktree is clean and the recent history contains the player rendering and responsive styling commits.
