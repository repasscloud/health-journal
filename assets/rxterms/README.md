# RxTerms medication catalogue

The U.S. National Library of Medicine publishes [RxTerms](https://lhncbc.nlm.nih.gov/MOR/RxTerms/)
from non-proprietary RxNorm content. The [HHS dataset record](https://datahub.hhs.gov/NIH/RxTerms/nsg5-zuaj)
identifies the Open Database License for the data. Health Journal distributes this derived
SQLite database under the [Open Database License 1.0](https://opendatacommons.org/licenses/odbl/1-0/).
The database can be downloaded directly from this directory and opened with ordinary
SQLite tooling with FTS5 support. The database also carries its source and license
URI in the `provenance` table.

This product uses publicly available data from the U.S. National Library of Medicine (NLM), National Institutes of Health, Department of Health and Human Services; NLM is not responsible for the product and does not endorse or recommend this or any other product.

[release.json](release.json) records the source release URL, source ZIP and generated
SQL SHA-256 checksums, the bundled SQLite checksum, and row counts. The derivation
joins the release's ingredient names by RxCUI, omits rows flagged for suppression
or retirement, retains full product labels, and generates a case-insensitive full-text
index. See [the build instructions](../../README.md#refresh-the-medication-catalogue)
for the reproducible import and verification commands.
