# Logo Favicon Design

## Goal

Use `app/assets/images/logo.png` as the browser-tab favicon and Apple touch icon on every page rendered with the application layout.

## Approach

Replace the existing static `/icon.png` and `/icon.svg` declarations in `app/views/layouts/application.html.erb` with Rails-generated icon links for `logo.png`. Resolving the image through the asset pipeline ensures production uses the digest-stamped asset URL and avoids duplicating the logo under `public/`.

The layout will emit:

- one PNG favicon link whose `href` resolves through the asset pipeline to `logo.png`; and
- one Apple touch icon link whose `href` resolves through the asset pipeline to the same image.

The existing SVG favicon declaration will be removed so browsers cannot prefer the old icon over the logo.

## Scope

This change affects only metadata in the shared application layout. It does not add a visible logo to the page body, alter CSS, resize or modify the source PNG, or change the PWA manifest.

## Testing

Add a request-level example for the home page that parses the rendered document head and verifies both the favicon and Apple touch icon declarations reference the asset-pipeline URL for `logo.png`. Run the focused request spec, then the full test suite and RuboCop.
