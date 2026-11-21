#!/usr/bin/env python3
"""Prepare a pinned, independently distributable RxTerms SQLite asset."""
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import re
import sqlite3
import tempfile
from urllib.request import urlopen
from zipfile import BadZipFile, ZipFile

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets/rxterms"
ASSET = ASSETS / "catalogue.sqlite"
MANIFEST = ASSETS / "release.json"
PAGE = "https://lhncbc.nlm.nih.gov/MOR/RxTerms/"
RELEASES = "https://data.lhncbc.nlm.nih.gov/public/rxterms/release/"
LICENSE = "https://opendatacommons.org/licenses/odbl/1-0/"
COLUMNS = (
    "RXCUI GENERIC_RXCUI TTY FULL_NAME RXN_DOSE_FORM FULL_GENERIC_NAME "
    "BRAND_NAME DISPLAY_NAME ROUTE NEW_DOSE_FORM STRENGTH SUPPRESS_FOR "
    "DISPLAY_NAME_SYNONYM IS_RETIRED SXDG_RXCUI SXDG_TTY SXDG_NAME PSN"
).split()
CREATE_SOURCE = "CREATE TABLE medications (" + ", ".join(
    f"{column} TEXT" + (" PRIMARY KEY NOT NULL" if column == "RXCUI" else "")
    for column in COLUMNS
) + ");"
SEARCH_SCHEMA = """
CREATE TABLE products (
    rxcui INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    generic TEXT NOT NULL,
    brand TEXT NOT NULL,
    strength TEXT NOT NULL,
    form TEXT NOT NULL,
    ingredient_count INTEGER NOT NULL,
    label TEXT NOT NULL
);
CREATE VIRTUAL TABLE product_search USING fts5(
    names, details, content='', prefix='2 3'
);
CREATE TABLE provenance (release TEXT, source TEXT, license TEXT);
PRAGMA user_version = 1;
"""


def digest(data):
    return hashlib.sha256(data).hexdigest()


def parse(data, columns):
    reader = csv.reader(io.StringIO(data.decode("utf-8-sig"), newline=""),
                        delimiter="|", quoting=csv.QUOTE_NONE)
    if next(reader, None) != columns:
        raise ValueError("Unexpected RxTerms header")
    for row in reader:
        if not row:
            continue
        if len(row) != len(columns) or not row[0].isascii() or not row[0].isdigit():
            raise ValueError(f"Invalid RxTerms row at line {reader.line_num}")
        if any("\0" in field for field in row):
            raise ValueError(f"NUL in RxTerms row at line {reader.line_num}")
        yield tuple(field.strip() or None for field in row)


def literal(value):
    return "NULL" if value is None else "'" + value.replace("'", "''") + "'"


def write_sql(path, rows):
    with path.open("w", encoding="utf-8", newline="\n") as output:
        output.write(CREATE_SOURCE + "\nBEGIN;\n")
        for row in rows:
            values = ", ".join(map(literal, row))
            output.write(f"INSERT INTO medications VALUES ({values});\n")
        output.write(
            "CREATE INDEX medications_brand ON medications (BRAND_NAME COLLATE NOCASE);\n"
            "CREATE INDEX medications_name ON medications (FULL_NAME COLLATE NOCASE);\n"
            "COMMIT;\n"
        )


def latest_release():
    with urlopen(PAGE, timeout=30) as response:
        html = response.read().decode()
    match = re.search(r'id="\$CURRENT-RELEASE"\s+href="([^"]+)"', html)
    if not match or not re.fullmatch(
        re.escape(RELEASES) + r"RxTerms[0-9]{6}\.zip", match[1]
    ):
        raise ValueError("Could not identify the current official RxTerms release")
    return match[1]


def import_release(archive, url, work, supplied_database=None):
    release = Path(url).stem.removeprefix("RxTerms")
    with ZipFile(io.BytesIO(archive)) as zipped:
        terms = zipped.read(f"RxTerms{release}.txt")
        ingredients_file = zipped.read(f"RxTermsIngredients{release}.txt")
    rows = list(parse(terms, COLUMNS))
    if not rows:
        raise ValueError("Empty RxTerms release")
    sql_path = work / "medications.sql"
    write_sql(sql_path, rows)
    ingredients = {}
    for rxcui, name, ingredient_id in parse(
        ingredients_file, ["RXCUI", "INGREDIENT", "ING_RXCUI"]
    ):
        if not name or not ingredient_id or not ingredient_id.isdigit():
            raise ValueError(f"Invalid ingredient for RxCUI {rxcui}")
        ingredients.setdefault(rxcui, {})[ingredient_id] = name

    output = work / ASSET.name
    with sqlite3.connect(":memory:") as source, sqlite3.connect(output) as db:
        source.executescript(sql_path.read_text(encoding="utf-8"))
        read_rows = f"SELECT {', '.join(COLUMNS)} FROM medications ORDER BY RXCUI"
        expected = sorted(rows)
        if source.execute(read_rows).fetchall() != expected:
            raise ValueError("SQL round trip changed RxTerms rows")
        if supplied_database is not None:
            with sqlite3.connect(supplied_database.resolve().as_uri() + "?mode=ro", uri=True) as supplied:
                imported = supplied.execute(read_rows).fetchall()
                if imported != expected:
                    raise ValueError("Supplied database differs from the official release")
                expected = imported
        db.executescript(SEARCH_SCHEMA)
        db.execute("INSERT INTO provenance VALUES (?, ?, ?)", (release, url, LICENSE))
        for row in expected:
            entry = dict(zip(COLUMNS, row))
            if entry["SUPPRESS_FOR"] or entry["IS_RETIRED"]:
                continue
            rxcui = entry["RXCUI"]
            brand = entry["BRAND_NAME"] or ""
            components = list(ingredients.get(rxcui, {}).values())
            generic = " / ".join(components) or entry["FULL_GENERIC_NAME"] or ""
            display = entry["DISPLAY_NAME"] or ""
            if entry["ROUTE"]:
                display = display.removesuffix(f' ({entry["ROUTE"]})')
            name = (display or brand) if brand else (generic or display)
            name = name or entry["FULL_NAME"]
            if not name:
                raise ValueError(f"Missing names for RxCUI {rxcui}")
            db.execute(
                "INSERT INTO products VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                (rxcui, name, generic, brand, entry["STRENGTH"] or "",
                 entry["RXN_DOSE_FORM"] or "", len(components), entry["FULL_NAME"] or ""),
            )
            db.execute(
                "INSERT INTO product_search(rowid, names, details) VALUES (?, ?, ?)",
                (rxcui, " ".join(filter(None, (
                    brand, generic, entry["DISPLAY_NAME"], entry["DISPLAY_NAME_SYNONYM"]
                ))), " ".join(filter(None, (
                    entry["FULL_NAME"], entry["FULL_GENERIC_NAME"], entry["PSN"]
                )))),
            )
        db.execute("INSERT INTO product_search(product_search) VALUES ('optimize')")
        db.execute("INSERT INTO product_search(product_search) VALUES ('integrity-check')")
        db.commit()
        db.execute("VACUUM")
        active_count = db.execute("SELECT count(*) FROM products").fetchone()[0]
    manifest = {
        "release": release,
        "source": url,
        "license": LICENSE,
        "source_zip_sha256": digest(archive),
        "medications_sql_sha256": digest(sql_path.read_bytes()),
        "catalogue_sha256": digest(output.read_bytes()),
        "source_rows": len(rows),
        "searchable_rows": active_count,
    }
    validate(output, manifest)
    return manifest


def validate(path, manifest):
    if digest(path.read_bytes()) != manifest["catalogue_sha256"]:
        raise ValueError(f"Catalogue checksum mismatch: {path}")
    with sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True) as db:
        if db.execute("PRAGMA quick_check").fetchall() != [("ok",)]:
            raise ValueError("Catalogue SQLite integrity check failed")
        if db.execute("PRAGMA user_version").fetchone() != (1,):
            raise ValueError("Unsupported catalogue schema")
        if db.execute("SELECT * FROM provenance").fetchall() != [
            (manifest["release"], manifest["source"], LICENSE)
        ]:
            raise ValueError("Catalogue provenance mismatch")
        count = manifest["searchable_rows"]
        if count <= 0 or count > manifest["source_rows"]:
            raise ValueError("Invalid RxTerms row counts")
        for table in ("products", "product_search"):
            if db.execute(f"SELECT count(*) FROM {table}").fetchone() != (count,):
                raise ValueError(f"Unexpected row count in {table}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_subparsers(dest="command", required=True)
    mode.add_parser("verify", help="Validate the pinned asset without network access")
    artifact = mode.add_parser("verify-artifact", help="Check the packaged asset bytes")
    artifact.add_argument("artifact", type=Path, help="APK or Runner.app")
    refresh = mode.add_parser("refresh", help="Generate SQL and package the current release")
    refresh.add_argument("--work", type=Path, default=ROOT / "build/rxterms")
    refresh.add_argument("--database", type=Path, help="Use an owner-built database after validation")
    refresh.add_argument("--release", help="Pin an official YYYYMM release instead of discovering latest")
    refresh.add_argument("--archive", type=Path, help="Use a cached ZIP with --release")
    args = parser.parse_args()

    if args.command == "verify":
        validate(ASSET, json.loads(MANIFEST.read_text()))
    elif args.command == "verify-artifact":
        if args.artifact.suffix == ".apk":
            with ZipFile(args.artifact) as apk:
                bundled = apk.read("assets/flutter_assets/assets/rxterms/catalogue.sqlite")
        else:
            bundled = (args.artifact / "Frameworks/App.framework/flutter_assets/assets/rxterms/catalogue.sqlite").read_bytes()
        if digest(bundled) != json.loads(MANIFEST.read_text())["catalogue_sha256"]:
            raise ValueError("Release artifact contains the wrong RxTerms catalogue")
    else:
        if args.release and not re.fullmatch(r"[0-9]{6}", args.release):
            parser.error("--release must be YYYYMM")
        if args.archive and not args.release:
            parser.error("--archive requires --release")
        url = f"{RELEASES}RxTerms{args.release}.zip" if args.release else latest_release()
        if args.archive:
            archive = args.archive.read_bytes()
        else:
            with urlopen(url, timeout=60) as response:
                archive = response.read()
        # Keep failed refreshes away from the pinned files.
        args.work.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=args.work) as temporary:
            stage = Path(temporary)
            manifest = import_release(archive, url, stage, args.database)
            (stage / "medications.sql").replace(args.work / "medications.sql")
            (stage / ASSET.name).replace(ASSET)
            MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")
        print(f"Pinned RxTerms {manifest['release']} with {manifest['searchable_rows']} searchable products")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, sqlite3.Error, KeyError, BadZipFile) as error:
        raise SystemExit(f"RxTerms catalogue: {error}") from error
