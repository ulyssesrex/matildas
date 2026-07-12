# Searchable Show Artists Design

## Goal

Clarify the artist choices in the shared admin new/edit show form and make existing artists easier to find without adding a JavaScript dependency.

## Form changes

- Replace the existing artist checkboxes with one native HTML `select` that supports multiple selections.
- Label the field `With artists`.
- Add a search input immediately above the multiselect. It has an `aria-label` of `Search artists` for assistive technology, but no visible label or placeholder text. A small Stimulus controller filters the displayed options by artist name as the administrator types.
- Keep selected artists selected and visible when filtering, so a search cannot hide selections or accidentally remove them.
- Preserve the current `admin_show_form[link_ids][]` parameter shape, including the selections shown when editing a show or redisplaying an invalid submission.
- Label the artist-creation section `Or Create An Artist`, matching the venue section's `Or Create A Venue` pattern.
- When there are no existing artists, retain a short empty-state message instead of rendering the search control and multiselect.

The shared partial supplies both the new and edit forms, so the same behavior and wording will apply to both pages.

## Progressive enhancement and accessibility

The multiselect remains a standard form control. If JavaScript is unavailable, administrators can still select multiple artists with the browser's native interaction. The search input is an enhancement managed by the project's existing Stimulus setup; no package or import-map dependency is added.

The multiselect receives a visible label, while the search input receives an accessible name through `aria-label`. Filtering is case-insensitive. An empty query restores every option.

## Testing

- Update the view spec to require the new labels and a multiple select rather than artist checkboxes.
- Verify existing artist selections render as selected options, particularly on the edit form.
- Keep the controller deliberately small, cover its HTML contract in the view spec, and verify filtering manually in the browser. The repository has no JavaScript unit-test setup, and this change will not add one.
- Run the focused RSpec files and RuboCop using the repository-local Bundler launcher.

## Scope

This change does not alter artist persistence, validation, creation fields, or database models. It does not introduce a full combobox, selection chips, autocomplete requests, or a third-party UI library.
