# ADR 0013 — Local PDF generation and Android document sharing

The generated report covers the current UTC calendar date and the preceding
29 dates through generation time. The report labels this window and shows
recorded medication time-zone identifiers and offsets where available. It
includes explicit administration status and correction provenance, regimen
details as plans, symptoms and revisions, versioned anatomical maps, and a
dated journal timeline. Each map uses the historical SVG viewBox and draws
the saved point and area relative to that geometry.

Use the platform-independent Dart PDF library with an offline bundled font
and the existing SVG assets. There is no print service, remote font lookup,
or report upload. Android saves directly into the destination selected via
the system create-document picker. For sharing, a non-exported FileProvider
serves only one PDF in an app-private report cache with a temporary read
grant. The app revokes and removes it after ten minutes, on replacement,
or at the next cold launch if the process was interrupted. A recipient can
keep its own copy. The export page tells the user that files are readable
outside the encrypted journal.

Host CI uses Poppler to verify extracted content, pagination and raster
marker geometry. The Android release is exercised with an isolated package.
Coverage for scripts beyond the bundled font and for other document
providers needs separate verification. Platform gates remain in place.
