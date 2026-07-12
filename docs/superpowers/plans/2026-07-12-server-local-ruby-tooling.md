# Server-local Ruby Tooling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide a checkout-local Bundler command that uses the server's Ruby 3.3 and never changes system, user, or deployment Ruby state.

**Architecture:** Git ignores `.local/`, which contains a server-only Bundler installation, application gems, launcher, and launcher test. A root `AGENTS.md` tells future agents to use the explicit launcher; application dependency and deployment files remain untouched.

**Tech Stack:** Bash, Ruby 3.3 and Bundler 4.0.10 from `/opt/rubies/ruby-3.3`, RubyGems

---

### Task 1: Ignore checkout-local tooling and instruct agents

**Files:**
- Modify: `.gitignore`
- Create: `AGENTS.md`

- [ ] **Step 1: Add `.local/` to `.gitignore`**

Append this repository-root rule:

```gitignore
# Server-local development tooling and gems.
/.local/
```

- [ ] **Step 2: Add agent command guidance**

Create `AGENTS.md` with:

```markdown
# Repository development commands

On this shared development server, use the checkout-local Bundler launcher for all Ruby commands. Do not install or modify system-wide or user-level Ruby tooling.

- RSpec: `.local/bin/bundle exec rspec`
- RuboCop: `.local/bin/bundle exec rubocop`
- Rails: `.local/bin/bundle exec rails`
- Other Ruby commands: `.local/bin/bundle exec <command>`

The launcher and installed gems are intentionally gitignored and server-specific. Deployment configuration must not refer to `.local/`.
```

- [ ] **Step 3: Verify ignore behavior**

Run: `mkdir -p .local && git status --short --ignored .local`

Expected: `!! .local/`

### Task 2: Test and create the local Bundler launcher

**Files:**
- Create: `.local/test/bundle_launcher_test.sh`
- Create: `.local/bin/bundle`

- [ ] **Step 1: Write the failing launcher test**

Create `.local/test/bundle_launcher_test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
output="$($root/.local/bin/bundle exec ruby -e 'puts RUBY_VERSION; puts Bundler::VERSION; puts Gem.dir')"

grep -Fx '3.3.11' <<<"$output"
grep -Fx '4.0.10' <<<"$output"
grep -Fx "$root/.local/bundle/ruby/3.3.0" <<<"$output"
```

- [ ] **Step 2: Run the test and confirm the launcher is missing**

Run: `bash .local/test/bundle_launcher_test.sh`

Expected: FAIL because `.local/bin/bundle` does not exist.

- [ ] **Step 3: Create the minimal launcher**

Create executable `.local/bin/bundle`:

```bash
#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ruby_root="${MOONRINGERS_RUBY_ROOT:-/opt/rubies/ruby-3.3}"
tool_home="$root/.local/tooling"

if [[ ! -x "$ruby_root/bin/ruby" ]]; then
  echo "Ruby executable not found: $ruby_root/bin/ruby" >&2
  exit 1
fi

if [[ ! -x "$ruby_root/bin/bundle" ]]; then
  echo "Bundler is missing: $ruby_root/bin/bundle" >&2
  exit 1
fi

export GEM_HOME="$tool_home"
export GEM_PATH="$tool_home:$ruby_root/lib/ruby/gems/3.3.0"
export BUNDLE_PATH="$root/.local/bundle"
export BUNDLE_USER_HOME="$root/.local/bundler"
export XDG_CACHE_HOME="$root/.local/cache"
export PATH="$ruby_root/bin:$PATH"
exec "$ruby_root/bin/ruby" "$ruby_root/bin/bundle" _4.0.10_ "$@"
```

- [ ] **Step 4: Make both scripts executable**

Run: `chmod +x .local/bin/bundle .local/test/bundle_launcher_test.sh`

### Task 3: Install isolated dependencies and verify commands

**Files:**
- Populate ignored directory: `.local/bundle`

- [ ] **Step 1: Confirm the compatible server Bundler is available**

Run:

```bash
/opt/rubies/ruby-3.3/bin/bundle _4.0.10_ --version
```

Expected: `Bundler version 4.0.10`.

- [ ] **Step 2: Run the launcher test**

Run: `bash .local/test/bundle_launcher_test.sh`

Expected: PASS and print Ruby 3.3.11, Bundler 4.0.10, and the checkout-local gem directory.

- [ ] **Step 3: Install application gems locally**

Run: `.local/bin/bundle install`

Expected: bundle completes and writes gems beneath `.local/bundle`.

- [ ] **Step 4: Run requested development commands**

Run: `.local/bin/bundle exec rspec`

Expected: RSpec completes without Bundler activation errors.

Run: `.local/bin/bundle exec rubocop`

Expected: RuboCop completes without Bundler activation errors.

- [ ] **Step 5: Confirm deployment files did not change**

Run: `git status --short && git diff -- Gemfile Gemfile.lock .ruby-version Dockerfile config/deploy.yml`

Expected: only `.gitignore`, `AGENTS.md`, and documentation are visible changes; the dependency/deployment diff is empty.
