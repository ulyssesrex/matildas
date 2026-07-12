# Show Cancellation Design

## Goal

Allow an administrator to cancel and later uncancel a show without removing it from the Shows table or losing its ordinary notes.

## Data Model

Add two fields to `shows`:

- `cancelled`, a non-null boolean defaulting to `false`
- `cancellation_notes`, optional text

The existing `notes` field continues to store ordinary show notes. Cancelling or uncancelling a show never clears either notes field.

## Admin Form

Extend `Admin::ShowForm` to load, validate, and persist `cancelled`, `notes`, and `cancellation_notes` with the other show attributes. Cancellation notes are optional.

The show form contains a Cancelled checkbox and separate ordinary-notes and cancellation-notes textareas. A focused Stimulus controller shows only the textarea appropriate to the checkbox state:

- When Cancelled is unchecked, show ordinary notes and hide cancellation notes.
- When Cancelled is checked, hide ordinary notes and show cancellation notes.

Both controls remain in the form so toggling the checkbox can swap between the two values without discarding either one. The controller changes presentation only; the server persists both submitted values independently. This behavior applies to both the create and edit forms.

When an existing cancelled show is opened for editing, the checkbox is checked and cancellation notes are visible. When it is uncancelled and reopened, ordinary notes are visible again with their prior value intact.

## Shows Table

Add a Notes cell to each show row.

For an active show:

- Render the existing formatted time, or `TBD` when no time is set.
- Render ordinary `notes` in the Notes cell.
- Use the existing text styling.

For a cancelled show:

- Keep the show in the same unexpired, chronological list.
- Add a cancellation-specific class to the row so all text and links in the row render red.
- Render exactly `SHOW CANCELLED` in the Time cell.
- Render `cancellation_notes` in the Notes cell instead of ordinary `notes`.

All other cells and the administrator Edit action remain available. Empty cancellation notes produce an empty Notes cell.

## Request and Persistence Flow

Permit the three new form attributes in the admin shows controller. `Admin::ShowForm` includes them when building or updating the `Show` inside its existing transaction. Failed validation or associated-record persistence continues to roll back all show changes, including cancellation state and both notes values.

## Testing

Form specs will verify:

- creating and updating cancellation state and both notes fields
- prefilling active and cancelled shows
- preserving ordinary notes through cancellation and uncancellation
- allowing blank cancellation notes
- rolling back cancellation changes with other show changes

Request specs will verify the controller permits and persists the new attributes for administrators.

View specs will verify:

- active shows display ordinary notes and their normal time or `TBD`
- cancelled shows remain present, receive the red-row class, display `SHOW CANCELLED`, and substitute cancellation notes
- ordinary notes do not appear in a cancelled row
- the form renders the checkbox and both controller-managed textareas with the correct initial visibility

The Stimulus behavior will receive a focused JavaScript test if the repository's existing JavaScript test setup supports controller tests; otherwise the view wiring and server-rendered fallback state will be covered by view specs.
