# Band Photo Design

## Goal

Display `app/assets/images/band_pic.jpg` on the home page immediately above the Music section without changing the page's general layout.

## Approach

Render the photo with Rails' `image_tag` inside the existing padded `<main>`, after any flash messages and directly before `<section id="music">`. The image will use descriptive alternative text and a dedicated CSS class.

The image-specific CSS will:

- display the image as a block;
- preserve its original 4:3 aspect ratio;
- keep its intrinsic width when space allows; and
- shrink it to fit narrower viewports without overflowing.

The navigation, main container, Music section, and remaining page sections will retain their existing structure and styles. The photo will not become a full-width hero, be cropped, or be forcibly upscaled.

## Testing

Add request-level coverage that parses the rendered home page and verifies the image:

- resolves through the asset pipeline to `band_pic.jpg`;
- has descriptive alternative text; and
- is the element immediately preceding the Music section.

Extend the stylesheet spec to verify the dedicated image class uses block display, automatic height, and a maximum width of 100%. Run the focused request and stylesheet specs, then the full RSpec suite and RuboCop.
