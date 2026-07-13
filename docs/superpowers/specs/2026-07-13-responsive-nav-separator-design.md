# Responsive Navigation Separator Design

## Goal

Add a thin white separator between the Moon Ringers brand and the primary navigation links. The separator must span the navigation bar's full height when the header uses one row and its full width when the header wraps into two rows.

## Markup and Layout

Keep the brand link as the first child of the primary navigation. Wrap the Music, Shows, and Misc links in a `.site-nav__links` container so the brand and navigation links form two explicit layout groups.

Move the navigation's spacing from the outer `.site-nav` container onto the brand and link groups. This lets the boundary between those groups reach the navigation bar's edges without negative margins or viewport-dependent positioning.

On viewports wider than `38rem`, keep both groups on one flex row. The brand expands into the available space, and `.site-nav__links` displays its links horizontally. A `1px solid var(--color-white)` left border on the link group forms a vertical rule spanning the navigation bar's full inner height.

At the existing `38rem` breakpoint, make both groups occupy a complete row. Remove the link group's left border and add a `1px solid var(--color-white)` top border. The result is a horizontal rule spanning the full navigation width between the brand row and the link row.

## Preserved Behavior

The existing link destinations, sticky positioning, typography, hover and focus treatments, black background, and white navigation bottom border remain unchanged. The link wrapper is structural and does not add another navigation landmark or change link semantics.

The existing wide and narrow navigation heights remain the scroll-offset reference. If moving spacing changes the header's measured height, update the custom properties to match the resulting intrinsic heights rather than allowing anchored sections to hide beneath the sticky header.

## Testing

Extend the home-page request spec to verify that the three section links are grouped in `.site-nav__links` after the brand link.

Extend the stylesheet spec to verify that the link group has a white one-pixel left border in the default layout and switches to a white one-pixel top border, with no left border, at the existing `38rem` breakpoint. Run the focused request and stylesheet specs, then run the full RSpec suite and RuboCop through the repository-local Bundler launcher.
