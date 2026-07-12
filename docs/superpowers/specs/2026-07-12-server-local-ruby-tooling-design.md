# Server-local Ruby tooling design

## Goal

Make tests, linters, and other Bundler-backed commands reliable for humans and agents on the shared development server without changing system Ruby, user-level Ruby tooling, or the application's eventual deployment environment.

## Design

Server-specific tooling will live under a gitignored `.local/` directory in this checkout. A `.local/bin/bundle` launcher will select the server-provided Ruby 3.3 and Bundler 4.0.10 installations and keep installed application gems under `.local/bundle`. Production remains pinned to the Bundler version recorded in `Gemfile.lock`; using the slightly older compatible server Bundler prevents local checks from rewriting the production lockfile.

The launcher will fail with a clear message if the expected server Ruby or Bundler is unavailable. It will not install or modify system or user gems.

Repository agent instructions will direct agents to invoke `.local/bin/bundle exec ...` for RSpec, RuboCop, Rails, and similar commands. Human shells may use the same explicit launcher. No shell activation is required, so fresh agent subprocesses behave consistently.

## Deployment isolation

The application `Gemfile`, `Gemfile.lock`, `.ruby-version`, Dockerfile, and deployment configuration remain unchanged. Production environments continue using their own Ruby and Bundler installations. Everything under `.local/` is excluded from Git and therefore cannot be included in a normal source-based deployment.

## Verification

Verification will confirm that:

1. The launcher reports the Ruby and Bundler versions expected by the repository.
2. Bundler installs gems only beneath `.local/`.
3. `.local/bin/bundle exec rspec` and `.local/bin/bundle exec rubocop` run successfully.
4. Git reports no application dependency or deployment-file changes.
