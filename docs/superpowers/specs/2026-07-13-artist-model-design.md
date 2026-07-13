# Artist Model Design

## Goal

Replace the `Link` concept with a dedicated `Artist` model and associate artists directly with shows. The application and resulting database schema will contain no `links` table, `links_shows` table, `Link` model, or `links.artist` column.

## Data Model

`Artist` is backed by an `artists` table and has required `name` and `url` attributes. `Artist` and `Show` use a `has_and_belongs_to_many` association backed by an `artists_shows` join table. The join table follows the existing indexing pattern with unique composite indexes in both lookup directions and no primary key.

A new destructive migration drops `links_shows` and `links`, then creates `artists` and `artists_shows`. Existing Link data is intentionally discarded because the application is not in production. Earlier migrations remain unchanged as migration history.

## Show Administration

The show form object accepts `artist_ids` for existing artists and `new_artists` rows containing `name` and `url`. Both fields are required for every started new-artist row. Blank rows are ignored.

On a valid submission, the form saves the show, replaces its existing artist associations with the selected artists, creates each submitted new artist, and associates the new records with the show. These operations remain inside the existing database transaction so an Artist or Show validation failure persists no partial changes.

An unknown submitted artist ID produces an Artist-specific validation error. An incomplete new-artist row produces a row-specific validation error. Editing a show preselects all currently associated artists.

The admin UI searches and selects existing artists and permits adding or removing multiple new-artist rows. Visible labels and submitted parameter names use Artist terminology. Link-specific Ruby names, view locals, and JavaScript row-controller identifiers are removed or renamed; generic reusable selection behavior may remain generic internally.

## Public Display and Loading

The home-page shows table renders the artists from `show.artists` as a comma-separated list of linked names prefixed with `w/`. Shows without artists leave the artist cell empty.

The page and admin controllers eager-load `:artists`, order available artists by name, and expose them as `@artists`. No compatibility layer or `@links` variable remains.

## Deletions

The `Link` model is removed. Link-focused tests are replaced with Artist tests. All runtime code, form attributes, parameters, view locals, and test data are updated to Artist terminology. The old migration files are retained, but after all migrations run the database contains neither Link table nor Link column state.

## Testing

Tests will verify:

- Artist name and URL requirements and the bidirectional show association.
- Show form creation and editing with existing and new artists.
- Rejection of unknown artist IDs and incomplete artist rows.
- Transaction rollback when an Artist cannot be saved.
- Controller parameter handling, eager-loaded edit state, and admin form rendering.
- Public rendering of associated artists and the empty state.
- Search filtering for existing artists.
- The final schema contains `artists` and `artists_shows` and contains no `links` or `links_shows` tables.
- Runtime application and spec files contain no remaining `Link` concept references.

## Out of Scope

The join association will not carry ordering, billing, set-time, or other per-show metadata. No data migration from Links is provided. No standalone Artist administration interface is added; artists are created and associated through the Shows admin form.
