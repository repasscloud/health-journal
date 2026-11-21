import io
from pathlib import Path
import sqlite3
import tempfile
import unittest
from zipfile import ZipFile

import catalogue


class RxTermsTest(unittest.TestCase):
    def test_import_filters_and_preserves_meaning(self):
        def row(rxcui, **fields):
            fields |= {"RXCUI": rxcui, "FULL_NAME": fields.get("FULL_NAME", "Sample")}
            return "|".join(fields.get(column, "") for column in catalogue.COLUMNS)

        terms = "\n".join([
            "|".join(catalogue.COLUMNS),
            row("1", BRAND_NAME="D'Example", FULL_NAME="Example 2 mg",
                STRENGTH="2 mg", DISPLAY_NAME_SYNONYM="demoalias"),
            row("2", RXN_DOSE_FORM="Oral Tablet", STRENGTH="2-4 mg"),
            row("3", BRAND_NAME="Retired", IS_RETIRED="TRUE"),
            row("4", BRAND_NAME="Suppressed", SUPPRESS_FOR="C"),
            row("5", FULL_NAME="Missing details"),
        ])
        archive = io.BytesIO()
        with ZipFile(archive, "w") as zipped:
            zipped.writestr("RxTerms200001.txt", terms)
            zipped.writestr("RxTermsIngredients200001.txt",
                            "RXCUI|INGREDIENT|ING_RXCUI\n1|Alpha|21\n2|Alpha|21\n2|Beta|22\n")
        with tempfile.TemporaryDirectory() as temporary:
            work = Path(temporary)
            manifest = catalogue.import_release(
                archive.getvalue(), catalogue.RELEASES + "RxTerms200001.zip", work
            )
            self.assertEqual(manifest["source_rows"], 5)
            self.assertEqual(manifest["searchable_rows"], 3)
            with sqlite3.connect(work / catalogue.ASSET.name) as db:
                self.assertEqual(
                    db.execute("SELECT rxcui, name, generic, strength, ingredient_count "
                               "FROM products ORDER BY rxcui").fetchall(),
                    [(1, "D'Example", "Alpha", "2 mg", 1),
                     (2, "Alpha / Beta", "Alpha / Beta", "2-4 mg", 2),
                     (5, "Missing details", "", "", 0)],
                )
                self.assertEqual(
                    db.execute("SELECT rowid FROM product_search "
                               "WHERE product_search MATCH 'demoal*'").fetchall(),
                    [(1,)],
                )
            sql = (work / "medications.sql").read_text()
            self.assertIn("'D''Example'", sql)
            self.assertIn("NULL", sql)
            with sqlite3.connect(":memory:") as db:
                with self.assertRaises(sqlite3.IntegrityError):
                    db.executescript(sql.replace("VALUES ('2',", "VALUES ('1',"))
            with self.assertRaisesRegex(ValueError, "checksum mismatch"):
                catalogue.validate(work / "medications.sql", manifest)

    def test_rejects_schema_drift(self):
        with self.assertRaisesRegex(ValueError, "header"):
            list(catalogue.parse(b"wrong|header", catalogue.COLUMNS))
        with self.assertRaisesRegex(ValueError, "line 2"):
            list(catalogue.parse(b"RXCUI|INGREDIENT\n1|a|extra",
                                 ["RXCUI", "INGREDIENT"]))
