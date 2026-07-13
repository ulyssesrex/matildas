# Bandcamp Music Players Design

## Goal

Add the four Bandcamp players stored in `/home/danielwb/co/matildas/embeds` to the home page Music section. Render them immediately after the Music heading in this order:

1. Magic Mirror
2. Dark Corners
3. Ample Shortage
4. Noise That Works

## Approach

Copy the four stable iframe definitions into a dedicated Rails view partial and render that partial immediately after the existing `<h2>Music</h2>` element. Keeping the iframe markup in this repository avoids a runtime or deployment dependency on the separate `matildas` checkout while keeping the home page template concise.

Preserve each source embed's Bandcamp player URL, accessible title, lazy-loading behavior, fallback link, and requested order. The iframe definitions are static page content; no controller, model, JavaScript, or database changes are needed.

## Presentation

Use the source site's responsive player presentation:

- stack all four iframe elements vertically;
- make every player a block element that fills the Music section width;
- use a 140px player height on standard viewports;
- remove iframe borders and retain a transparent background;
- place 24px of vertical space between adjacent players; and
- reduce the player height to 120px inside the site's existing narrow-screen breakpoint.

The Music heading remains the first element in the section, with the first player immediately after it. The rest of the home page layout remains unchanged.

## Testing

Add view coverage that renders the home page and verifies:

- exactly four Bandcamp iframe elements appear in the Music section;
- the Music heading precedes the players;
- the iframe player URLs occur in the requested album order;
- the source titles, fallback links, and lazy-loading attributes are preserved; and
- no content is inserted between the heading and the first player container.

Extend the stylesheet spec to verify the full-width stacked-player dimensions, border and background treatment, 24px adjacent-player spacing, and 120px narrow-screen height. Run the focused view and stylesheet specs, then the complete RSpec suite and RuboCop using the checkout-local Bundler launcher.
