# Optional Show Time Design

## Goal

Allow an administrator to save a show with a required date and no time. Public and admin show listings display `TBD` for an unknown time while preserving normal behavior for shows with a known time.

## Data model and migration

Replace the current `shows.time` datetime with two independent columns:

- `shows.date`, a non-null date
- `shows.time`, a nullable time

The migration will preserve existing data by renaming the old datetime column temporarily, adding the new columns, and backfilling each record. Each old datetime is converted to Eastern Time before its calendar date and clock time are copied into the new columns. Once all records are backfilled, the date is made non-null and the temporary datetime column is removed.

Application code treats the stored clock time as Eastern local time. It no longer converts admin input to UTC because a database time value has no date or time zone.

## Admin form behavior

The show form continues to require a valid ISO date and price. Time becomes optional. When present, it must remain a valid 24-hour `HH:MM` value.

Saving writes the parsed date to `show.date`. A supplied time is parsed and written to `show.time`; a blank time writes `nil`. Editing reads the date and time independently, leaving the time input blank for a show whose time is unknown. The HTML time field is no longer marked required.

Existing venue and link behavior remains unchanged.

## Listing and lifecycle behavior

The shows table formats `show.date` as the current human-readable date. It formats a present `show.time` as a 12-hour clock time and displays `TBD` when the time is absent.

Upcoming-show filtering uses `show.date`, not `show.time`. A show remains visible through the same two-week grace period based on its calendar date, including when its time is unknown.

Listings sort by date ascending. Within a date, shows with known times sort chronologically before shows with unknown times.

## Error handling

Missing or invalid dates continue to produce date validation errors. Invalid nonblank times produce time validation errors. A blank time is valid. Existing transaction handling and persistence-error reporting remain unchanged.

## Testing

Focused specs will cover:

- accepting and persisting a blank time with a required date
- parsing and persisting a supplied clock time without UTC conversion
- rejecting a missing date and an invalid nonblank time
- prefilling edit forms for both known and unknown times
- displaying `TBD` for an unknown time and formatting known times normally
- retaining unknown-time shows in the unexpired scope based on date
- ordering known times before unknown times on the same date
- request-level creation and editing with a blank time
- migration structure and backfill logic through static review

Ruby, Rails, Bundler, and RSpec commands are unavailable in the current environment. The specs will be written, and verification will be limited to static inspection and non-Ruby checks.
