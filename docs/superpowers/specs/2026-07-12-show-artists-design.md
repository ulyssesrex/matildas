# Show Artists Design

## Goal

Replace the public Shows table's generic Links cell with an Artists cell that lists only links classified as artists. Keep the existing `Link` model so non-artist links remain available for other uses.

## Data model

Add an `artist` boolean column to `links` with a database default of `false` and a `NOT NULL` constraint. Existing records therefore remain ordinary links unless explicitly reclassified.

The existing `Show`/`Link` many-to-many association remains unchanged.

## Admin Show form

The Show form treats every new link row as an artist:

- Rename user-facing Link labels and hints in this form to Artist terminology.
- Continue collecting a name and URL for each new artist.
- Save every `Link` created through these rows with `artist: true`; the client does not submit or control the flag.
- Present the existing-record selector as Existing Artists. Selecting an existing record associates it with the show but does not change its global `artist` classification. Consequently, a legacy non-artist selected there remains absent from the public Artists cell.

## Public Shows table

Rename the visual cell from Links to Artists and render only associated links where `artist` is true. When at least one artist exists, the cell contains `w/ ` followed by the linked artist names separated by commas, preserving the association's display order. Each name links to that record's URL.

When a show has no artist links, the Artists cell remains empty. Associated non-artist links are not rendered in this table.

## Error handling and compatibility

Existing validation for new-link name and URL completeness remains in place, with user-facing messages and labels adjusted to Artist terminology where applicable. The database default makes existing data and callers that create ordinary links backward compatible.

## Testing

Automated coverage will verify:

- the `artist` default for ordinary links;
- Show form creation of artist links;
- Artist terminology in the admin form;
- the `w/` prefix and comma-separated linked artist names;
- exclusion of associated non-artist links; and
- an empty Artists cell when no artists are associated.
