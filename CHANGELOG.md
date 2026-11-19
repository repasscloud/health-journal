# Changelog

## Unreleased

### Added

- Enabled encrypted single-profile record entry in Android production.
- Added optional Android journal PIN and app-switcher privacy.
- Added medication revisions, explicit scheduled-dose linkage, symptom edit
  history, and Timeline date filtering and pagination.

- Added illustrated front and back body maps for symptom entry, with distinct
  anatomical landmarks for each view.
- Added a dedicated grayscale Hj branding asset for the in-app header.

### Changed

- New pain observations use body-map v2. Tap detection follows the silhouette
  for each view, and markers use coordinates relative to the rendered map.
  Accessible region buttons place markers inside the new artwork.
- Retained the bundled v1 SVGs and region geometry for existing observations.
- Updated the Hj monogram to grayscale across the startup animation, iOS and
  iPadOS app icons, Android legacy and adaptive launchers, and the web favicon
  and PWA icons. Updated the launcher design previews to match.
- Kept one Timeline filter active at all times and added spacing between
  wrapped filter rows.

### Tests

- Added checks for v2 asset selection, silhouette taps, anatomical laterality,
  and compatibility with v1 observations.
- Added coverage for Timeline filter selection and wrapping, and updated the
  startup animation checks for the grayscale palette.
