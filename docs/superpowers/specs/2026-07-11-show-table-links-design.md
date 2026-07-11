# Show Table Links Design

## Goal

Make Venue map destinations and Show Links directly accessible from each row of the public Shows table.

## Rendering

Keep the existing table structure and append one final cell to every Show row.

When a Show has a Venue:

- If the Venue's `map_url` is present, render the Venue name as an anchor whose `href` is the `map_url`.
- If `map_url` is blank, render the Venue name as plain text.

A Show without a Venue continues rendering a blank Venue cell.

In the row-final cell, render every associated Link as an anchor using the Link's `name` as its text and `url` as its `href`. Links open in the same tab and are separated by spaces. A Show without Links receives an empty final cell.

## Data Access

The existing home-page query already eager-loads both `:venue` and `:links`, so rendering these anchors requires no controller or query changes and introduces no per-row association queries.

## Testing

Extend the home view spec to verify:

- a Venue with a Map URL renders its name as an anchor with the exact URL
- a Venue without a Map URL remains plain text
- multiple Show Links render as anchors in the final cell with their exact names and URLs
- a Show without Links renders an empty final cell

No model, database, authorization, or form behavior changes are in scope.
