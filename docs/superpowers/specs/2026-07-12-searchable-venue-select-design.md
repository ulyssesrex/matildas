# Searchable Venue Select Design

## Goal

Make the Existing Venue field on the admin new/edit Show form searchable while preserving the existing rule that a Show has at most one Venue.

## Design

Reuse the existing `artist-select` Stimulus controller, whose filtering behavior already works for both single- and multiple-select elements. Add a search input to the Existing Venue form field and connect it and the Venue select to that controller.

The Venue select will remain a scalar `venue_id` field without the `multiple` attribute. It will render as a visible list sized consistently with the Artist selector. The only visible field label will remain `Existing Venue`; the search input will have an accessible `Search venues` label through `aria-label` but no additional visible label.

Each option will display the Venue name followed by its available city and state in parentheses, for example `The Pour House (Raleigh, NC)`. Blank location parts will be omitted, and no empty parentheses will be rendered. Because filtering operates on the option text, Venue searches will match names and locations.

Filtering will hide unselected options that do not contain the case-insensitive query. A selected Venue will remain visible even when it does not match the query, matching the Artist selector behavior.

No model, form object, controller parameter, or persistence changes are needed.

## Testing

- Extend the form view spec to verify the searchable single-select structure and labels.
- Verify Venue option text includes its location and handles missing location parts.
- Add a system spec that verifies Venue filtering, selection preservation, and clearing the search.
- Run the focused specs and relevant existing request/form specs.
