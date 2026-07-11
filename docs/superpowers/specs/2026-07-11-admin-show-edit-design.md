# Admin Show Editing Design

## Goal

Allow a logged-in administrator to open a Show from the Shows table, edit it on a separate page, and return to the home page after a successful submission. Visitors and non-admin users must not see edit controls or gain access to the edit endpoints.

## User Interface

The home page Shows table gains a final Edit column only when `admin?` is true. Each Show row contains an Edit button in that column linking to `/admin/shows/:id/edit`. Non-admin visitors receive neither the column nor its buttons.

The edit page uses the existing admin Show form presentation. Its heading and submit label indicate that an existing Show is being edited. The form is prefilled with the Show's date and time in Eastern Time, price, selected Venue, and selected existing Links. As with Show creation, the administrator can instead create a new Venue and can add new Links.

## Architecture

Add `edit` and `update` routes to the existing admin Shows resource and corresponding actions to `Admin::ShowsController`. Both actions remain protected by `require_admin`.

Extend `Admin::ShowForm` so it can be initialized with an existing Show. In edit mode it derives initial form values from that record and updates the record inside the same transaction used to resolve Venue and Link associations. In create mode it retains its current behavior. Shared validation applies to both modes.

Generalize the existing form partial so callers supply the form URL, heading, submit label, and error wording. The home page continues using it for creation. A new edit template uses it for updates and supplies the ordered Venue and Link collections.

## Data Flow

For `GET /admin/shows/:id/edit`, the controller loads the Show with its associations, constructs a record-backed form, loads available Venues and Links, and renders the edit page.

For `PATCH /admin/shows/:id`, the controller loads the Show and constructs the form from submitted parameters. A valid form resolves either the selected existing Venue or a newly created Venue, updates the Show's time, price, Venue, and selected existing Links, creates any submitted new Links, and associates those new Links with the Show. The operation is transactional. Success redirects to the root path with a notice.

An invalid form does not persist partial changes. The controller reloads the Venue and Link choices and renders the edit page with HTTP 422, validation messages, and the submitted values intact.

## Authorization and Missing Records

Unauthenticated requests to edit or update are redirected to the admin login page by the existing authentication concern. Authenticated non-admin users receive HTTP 403. Normal Rails record lookup behavior handles unknown Show IDs with HTTP 404.

## Testing and Verification

View specs cover the Edit column and buttons for admins and their absence for non-admins. Request specs cover edit and update authorization, edit-form prepopulation, successful field and association updates, creation of a new Venue and Links during editing, the root-page redirect, and invalid submission redisplay without persistence.

Implementation will follow test-first development. Because Ruby, Rails, Bundler, and RSpec commands are unavailable in this environment, automated tests will be written but not executed. Static checks will inspect routes, templates, controller/form integration, syntax structure, and the final diff without invoking Ruby tooling.
