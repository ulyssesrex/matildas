# Navigation Link Heading Size Design

## Goal

Make every primary navigation link, including the Moon Ringers brand link, the same font size as the home-page section headings.

## Design

Define a `--body-heading-font-size` custom property with a value of `1.5rem` in the existing `:root` rule. Apply that property to both `.home-section h2` and `.site-nav__link`.

This makes the size relationship explicit instead of relying on the browser's default `h2` styling. It changes no markup, navigation behavior, font weight, spacing, or other heading styles.

## Verification

Run the focused page request spec and RuboCop using the repository-local Bundler launcher. Inspect the stylesheet diff to confirm that the shared property is used by both selectors and that no unrelated styles changed.
