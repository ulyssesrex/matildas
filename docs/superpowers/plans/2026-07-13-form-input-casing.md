# Form Input Casing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve the displayed and submitted casing of user-entered input while keeping select labels, buttons, and non-editable interface text uppercase.

**Architecture:** Add a low-level CSS exception for inputs and textareas, then remove the later shared-control override that currently defeats it. Keep selects under the global uppercase rule and submit inputs under their explicit action rule; add request coverage that documents the independent email-normalization and password-case behavior of authentication.

**Tech Stack:** Rails ERB forms, CSS, Active Record normalization, `has_secure_password`, RSpec request and stylesheet specs

---

## File Structure

- Modify `spec/requests/admin_sessions_spec.rb`: characterize mixed-case email normalization and case-sensitive password authentication.
- Modify `spec/stylesheets/application_spec.rb`: specify the casing boundary between editable text, selects, and submit actions.
- Modify `app/assets/stylesheets/application.css`: reset case transformation for inputs and textareas while retaining uppercase presentation elsewhere.

The existing unstaged `.gitignore` edit is outside this feature. Do not stage, modify, restore, or commit it.

### Task 1: Protect mixed-case authentication behavior

**Files:**
- Modify: `spec/requests/admin_sessions_spec.rb:12-28`

- [ ] **Step 1: Replace the successful-login example with mixed-case credentials**

Replace the `describe "POST /admin/session"` block with:

```ruby
describe "POST /admin/session" do
  let!(:admin) do
    User.create!(
      email_address: "Admin.User@Example.COM",
      password: "MiXeD-Pass9",
      password_confirmation: "MiXeD-Pass9",
      admin: true
    )
  end

  it "normalizes email casing and accepts the exact mixed-case password" do
    expect(admin.reload.email_address).to eq("admin.user@example.com")

    post admin_session_path, params: {
      email_address: "ADMIN.USER@example.com",
      password: "MiXeD-Pass9"
    }

    expect(response).to redirect_to(root_path)
  end

  it "keeps passwords case-sensitive" do
    post admin_session_path, params: {
      email_address: "admin.user@example.com",
      password: "mixed-pass9"
    }

    expect(response).to redirect_to(new_admin_session_path)
  end
end
```

This is characterization coverage for existing server behavior. It is expected to pass before the CSS change because CSS has no role in model normalization or password verification.

- [ ] **Step 2: Run the admin-session request spec**

Run:

```bash
.local/bin/bundle exec rspec spec/requests/admin_sessions_spec.rb
```

Expected: 3 examples, 0 failures. The result confirms that email lookup is normalized and password matching remains case-sensitive before presentation CSS changes.

- [ ] **Step 3: Commit the authentication coverage**

```bash
git add spec/requests/admin_sessions_spec.rb
git commit -m "Test mixed-case admin authentication"
```

Expected: only `spec/requests/admin_sessions_spec.rb` is committed; `.gitignore` remains unstaged in the original checkout and is absent from the isolated implementation worktree.

### Task 2: Preserve casing in editable controls

**Files:**
- Modify: `spec/stylesheets/application_spec.rb:6-26`
- Modify: `app/assets/stylesheets/application.css:34-41,192-213`

- [ ] **Step 1: Write the failing stylesheet example**

Add this example after the heading-size example in `spec/stylesheets/application_spec.rb`:

```ruby
it "preserves editable text casing while keeping selections and actions uppercase" do
  expect(stylesheet).to match(
    /input,\s*textarea\s*\{[^}]*text-transform:\s*none;/m
  )
  expect(stylesheet).not_to match(
    /\.form-field input\[type="date"\],[^{]*\{[^}]*text-transform:\s*uppercase;/m
  )
  expect(stylesheet).not_to match(
    /select[^{]*\{[^}]*text-transform:\s*none;/m
  )
  expect(stylesheet).to match(
    /\.form-button,\s*input\[type="submit"\]\s*\{[^}]*text-transform:\s*uppercase;/m
  )
end
```

The first expectation requires a general editable-control reset. The second prevents the more specific shared form-control rule from overriding that reset. The last two expectations keep selects outside the reset and preserve uppercase submit actions.

- [ ] **Step 2: Run the stylesheet spec to verify it fails**

Run:

```bash
.local/bin/bundle exec rspec spec/stylesheets/application_spec.rb
```

Expected: 1 failure because there is no `input, textarea` normal-case rule and the shared form-control declaration still applies uppercase transformation.

- [ ] **Step 3: Add the editable-control reset**

Immediately after the existing `a` rule in `app/assets/stylesheets/application.css`, add:

```css
input,
textarea {
  text-transform: none;
}
```

- [ ] **Step 4: Remove the conflicting shared-control declaration**

In the shared form-control rule beginning with `.form-field input[type="date"]`, remove only this declaration:

```css
text-transform: uppercase;
```

Do not change the selector list. In particular, keep `.form-field select` in the shared visual styling rule so selects retain the same black surface, white border, typography, sizing, and spacing while inheriting uppercase presentation from `html`.

- [ ] **Step 5: Run the focused stylesheet and authentication specs**

Run:

```bash
.local/bin/bundle exec rspec spec/stylesheets/application_spec.rb spec/requests/admin_sessions_spec.rb
```

Expected: all examples pass. Inputs and textareas now display their underlying casing, selects remain uppercase without value mutation, submit inputs remain uppercase, and mixed-case authentication behavior remains intact.

- [ ] **Step 6: Inspect the focused diff**

Run:

```bash
git diff --check -- app/assets/stylesheets/application.css spec/stylesheets/application_spec.rb
git diff -- app/assets/stylesheets/application.css spec/stylesheets/application_spec.rb
```

Expected: the whitespace check prints nothing. The diff contains one CSS reset, removal of one conflicting declaration, and one stylesheet example.

- [ ] **Step 7: Commit the casing fix**

```bash
git add app/assets/stylesheets/application.css spec/stylesheets/application_spec.rb
git commit -m "Preserve form input casing"
```

### Task 3: Verify the completed change

**Files:**
- Verify: `app/assets/stylesheets/application.css`
- Verify: `spec/stylesheets/application_spec.rb`
- Verify: `spec/requests/admin_sessions_spec.rb`

- [ ] **Step 1: Run the full RSpec suite**

Run:

```bash
.local/bin/bundle exec rspec
```

Expected: all examples pass with zero failures; the repository's existing pending examples may remain pending.

- [ ] **Step 2: Run RuboCop**

Run:

```bash
.local/bin/bundle exec rubocop
```

Expected: no offenses.

- [ ] **Step 3: Confirm the feature worktree is clean**

Run:

```bash
git status --short
```

Expected: no output in the isolated feature worktree.
