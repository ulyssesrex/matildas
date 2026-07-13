# Admin Root Route Design

## Goal

Make `GET /admin` display the existing admin login page while preserving `/admin` in the browser address bar.

## Design

Add a route within the existing `admin` namespace that maps the namespace root directly to `Admin::SessionsController#new`. Keep the existing `GET /admin/session/new` route unchanged so current links and helpers continue to work.

No redirect or new controller action is needed. The new route reuses the existing session form, controller behavior, and authentication flow.

## Testing

Add a routing example proving that `GET /admin` routes to `admin/sessions#new`. Run the focused routing spec, then the full test suite and RuboCop.
