# Admin Show Form Design

## Goal

Add a form directly below the public Shows table that is visible and usable only by authenticated admin users. The form creates a Show, optionally associates an existing or newly created Venue, and associates any combination of existing and newly created Links.

## Architecture

The public `PagesController#home` action continues to load unexpired Shows for every visitor. When the current session belongs to an admin, it also prepares an `Admin::ShowForm` and the existing Venue and Link choices needed by the form.

The form posts to `Admin::ShowsController#create`. This endpoint independently requires an authenticated admin; conditional rendering is only a user-interface concern and is not the authorization boundary.

`Admin::ShowForm` owns the submission-specific validation and persistence workflow. It accepts:

- `date`, `time`, and `price`
- an optional existing Venue ID
- optional new Venue attributes: `name`, `city`, `state`, and `map_url`
- zero or more existing Link IDs
- zero or more new Link attribute pairs: `name` and `url`

The form object parses Date and Time in `Eastern Time (US & Canada)` and assigns the resulting `ActiveSupport::TimeWithZone` directly to `Show#time`. Active Record's default UTC persistence serializes the value to UTC. The existing Shows table continues converting stored values to Eastern Time for display.

All new records and associations are saved within one database transaction. A validation or persistence failure creates no Show, Venue, Link, or join-table row.

## Page and Form Layout

The form appears immediately below the Shows table only when `Current.session.user.admin?` is true.

On wider screens it uses two columns:

- The left panel contains Date, Time, Price, existing Link checkboxes, dynamic new Link rows, and the submit button.
- The right panel contains the existing Venue selector and the new Venue Name, City, State, and Map URL inputs.

On narrow screens the panels stack into a single column. Existing Links are shown as labeled checkboxes. The new Links area begins with one blank Name/URL row and provides controls to add or remove rows dynamically. Blank Link rows are ignored.

The dynamic Link behavior uses a small Stimulus controller. JavaScript improves the editing experience only; server-side validation and authorization remain authoritative.

## Validation Rules

- Date, Time, and Price are required.
- Date and Time must combine into a valid Eastern timestamp.
- A Venue is optional, consistent with the existing optional `Show#venue` association.
- Selecting an existing Venue while entering any new Venue attribute is an error.
- If any new Venue attribute is entered, all four new Venue attributes are required.
- Existing and new Links may be associated with the same Show.
- A nonblank new Link row must contain both Name and URL.
- Existing Venue and Link IDs must resolve to records in the database. Unknown IDs are validation errors.
- Duplicate submitted existing Link IDs are normalized so each Link is associated only once.

## Submission Results and Errors

On success, the controller redirects to `root_path(anchor: "shows")` and displays a confirmation notice.

On failure, the controller renders the home page with an unprocessable-content status. It reloads the Shows table and choice collections, preserves submitted field values and selections, and displays both an error summary and field-level errors. No submitted record is persisted.

## Authorization

Unauthenticated visitors and authenticated non-admin users may continue viewing the public home page and Shows table. They do not see the form. Direct create requests from either group are rejected. Existing authentication redirects unauthenticated requests to the admin sign-in page; authenticated non-admin requests receive a forbidden response.

## Testing

Request specs cover:

- form visibility for admins and absence for unauthenticated/non-admin visitors
- create-endpoint authorization for each user category
- creating a Show with an existing Venue
- creating a Show and a complete new Venue atomically
- combining selected existing Links with multiple new Links
- Eastern input serialized as the correct UTC timestamp during both daylight-saving and standard time
- redisplay and preservation of submitted values after validation errors
- transaction rollback when any part of persistence fails

Form-object specs cover required Show fields, invalid timestamps, mutually exclusive Venue choices, conditional new-Venue completeness, paired new-Link fields, invalid record IDs, and duplicate existing Link IDs.

View or system-level coverage verifies the two-column structure, its responsive styling hooks, and the add/remove controls for dynamic Link rows.

## Out of Scope

This change does not add editing or deletion of Shows, Venues, or Links; cleanup of duplicate existing records; venue autocomplete; or changes to the public Shows table beyond displaying newly created Shows through its existing query and formatting.
