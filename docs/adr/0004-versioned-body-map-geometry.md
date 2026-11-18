# 0004 — Versioned body-map geometry

## Status

Accepted on 2026-11-18.

## Decision

Use the bundled v2 SVGs for new pain observations. Store the selected view and
asset version with normalized coordinates. Keep both bundled v1 SVGs and the
original v1 polygon geometry so that existing observations retain their
coordinates and region labels.

Use the v2 SVG silhouette path for hit testing in each view. Validate coordinates
synchronously using Flutter's filled-path containment and `path_parsing`, which
was already in the dependency graph. Keep the silhouette path data in Dart for
record validation without asynchronous asset loading. A test checks that it
matches both SVGs. Region buttons use anchors inside each silhouette, and map
taps and marker positions use the same laid-out image rectangle.

The timeline displays saved locations as text. Future graphical history and
report renderers must select the bundled asset by the observation's recorded
version and view.
