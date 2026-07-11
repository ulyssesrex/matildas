# High-Contrast Site Style Design

## Goal

Restyle the Rails site with a minimalist black-and-white aesthetic. Present all rendered text in uppercase Helvetica without modifying source strings, submitted values, or stored data.

## Visual System

The global page surface is pure black with white text. Every rendered element inherits `Helvetica, Arial, sans-serif` and `text-transform: uppercase`. Typography, spacing, weight, and one-pixel rules provide hierarchy. The interface does not use gray tones, semantic colors, shadows, gradients, or rounded decorative treatments.

Links remain identifiable through underlines on interaction or persistent underlines where needed. Keyboard focus uses a clear white outline with sufficient offset against the black background.

Uppercase is presentation-only. Existing copy and user-entered values retain their original casing in markup, submissions, and persistence.

## Component Treatment

The sticky navigation shares the black page background and uses a thin white bottom rule for separation.

Show tables use white grid lines and generous cell padding. Existing horizontal scrolling remains available on narrow screens.

Form panels, fieldsets, inputs, selects, buttons, flash messages, hints, and validation errors use only black and white. Inputs have black surfaces, white text, and white borders. Primary buttons invert to white backgrounds with black text; secondary buttons remain black with white borders and text.

Feedback and validation states communicate through borders, font weight, labels, and semantic markup rather than red, green, or tinted backgrounds.

## Scope

The styling applies globally through the Rails application stylesheet, including the homepage, authenticated show form, and admin login. Inline red and green styles on admin login feedback are removed so those messages inherit the shared monochrome feedback treatment.

Page structure, written copy, application data, routes, and behavior remain unchanged. The legacy root `index.html` is not part of the active Rails layout and is outside this change.

## Responsive and Accessibility Behavior

Existing responsive navigation and form layouts remain intact. Table overflow continues to support small screens. Controls retain visible hover and keyboard focus states. Semantic error and status roles remain unchanged, and no state depends on color alone.

## Verification

View coverage verifies that admin login feedback no longer renders color-specific inline styles. Existing view and request specs verify that page content and behavior remain intact. After focused specs pass, run the full RSpec suite and RuboCop.
