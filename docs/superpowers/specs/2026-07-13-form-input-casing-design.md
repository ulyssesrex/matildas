# Form Input Casing Design

## Goal

Display user-entered text in its original casing while preserving the site's uppercase presentation for non-editable text, select option labels, and form actions.

## Root Cause

The application applies `text-transform: uppercase` to the `html` element, so descendants inherit uppercase presentation. The shared form-control declaration also explicitly applies uppercase transformation to email, password, search, text, URL, date/time, select, and textarea controls. This affects how entered characters are drawn but does not modify DOM values, submitted parameters, or persisted data.

## Styling

Add a general `input, textarea` rule with `text-transform: none`. Remove the explicit uppercase transformation from the shared form-control declaration. This makes every current and future input field display its value without a case transformation and keeps textareas consistent.

Leave selects out of the reset so their option labels continue to inherit uppercase presentation. CSS transformation does not alter an option's `value` attribute or submitted value. Keep the existing later submit-button rule, which explicitly restores uppercase presentation for submit inputs. Button text, labels, headings, navigation, and other non-editable content remain uppercase.

## Authentication and Data Integrity

No controller, model, or persistence behavior changes. Browsers submit the input's underlying value, not its transformed presentation.

`User` intentionally strips and lowercases `email_address` through its Active Record normalization. Rails applies that normalization to both assignments and attribute-based queries, so an email can be entered with different casing and still reference the same account. `has_secure_password` continues to treat passwords as case-sensitive, so a mixed-case password must be entered with the same casing used when it was created.

Other form values continue through their existing parameter and persistence paths without CSS-driven case conversion.

## Testing

Extend the stylesheet spec to require normal casing for inputs and textareas, inherited uppercase presentation for selects, and explicit uppercase presentation for submit inputs.

Extend the admin-session request spec with a mixed-case email and password example. Create an administrator with mixed-case credentials, verify that the email is normalized, authenticate using a differently cased version of the same email and the exact mixed-case password, and expect a successful redirect. Also submit the password with different casing and expect authentication to fail, proving password case remains significant.

Run the focused stylesheet and admin-session request specs, then run the full RSpec suite and RuboCop through the checkout-local Bundler launcher.
