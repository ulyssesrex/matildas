# Admin Root Route Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route `GET /admin` directly to the existing admin login action without redirecting the browser.

**Architecture:** Define the admin namespace root as an additional route to `Admin::SessionsController#new`. Protect the behavior with the existing focused routing spec; no controller or view changes are needed.

**Tech Stack:** Ruby on Rails routing, RSpec routing specs, RuboCop

---

### Task 1: Add the admin namespace root route

**Files:**
- Modify: `spec/routing/admin_pages_routing_spec.rb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Write the failing routing spec**

Replace the empty example group in `spec/routing/admin_pages_routing_spec.rb` with:

```ruby
require "rails_helper"

RSpec.describe "admin page routes", type: :routing do
  it "routes the admin root directly to the admin login page" do
    expect(get: "/admin").to route_to(
      controller: "admin/sessions",
      action: "new"
    )
  end
end
```

- [ ] **Step 2: Run the focused spec to verify it fails**

Run: `.local/bin/bundle exec rspec spec/routing/admin_pages_routing_spec.rb`

Expected: FAIL because `GET /admin` is not routable.

- [ ] **Step 3: Add the minimal route**

Add the namespace root before the resource routes in `config/routes.rb`:

```ruby
namespace :admin do
  root to: "sessions#new"
  resource :session, only: [ :new, :create, :destroy ]
  resources :shows, only: [ :create, :edit, :update ]
end
```

- [ ] **Step 4: Run the focused spec to verify it passes**

Run: `.local/bin/bundle exec rspec spec/routing/admin_pages_routing_spec.rb`

Expected: 1 example, 0 failures.

- [ ] **Step 5: Commit the behavior change**

```bash
git add config/routes.rb spec/routing/admin_pages_routing_spec.rb
git commit -m "Route admin root to login"
```

### Task 2: Verify the repository

**Files:**
- Verify only; no file changes expected

- [ ] **Step 1: Run the full RSpec suite**

Run: `.local/bin/bundle exec rspec`

Expected: All examples pass with 0 failures.

- [ ] **Step 2: Run RuboCop**

Run: `.local/bin/bundle exec rubocop`

Expected: No offenses detected.
