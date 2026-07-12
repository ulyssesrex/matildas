# Repository development commands

On this shared development server, use the checkout-local Bundler launcher for all Ruby commands. Do not install or modify system-wide or user-level Ruby tooling.

- RSpec: `.local/bin/bundle exec rspec`
- RuboCop: `.local/bin/bundle exec rubocop`
- Rails: `.local/bin/bundle exec rails`
- Other Ruby commands: `.local/bin/bundle exec <command>`

The launcher and installed gems are intentionally gitignored and server-specific. Deployment configuration must not refer to `.local/`.
