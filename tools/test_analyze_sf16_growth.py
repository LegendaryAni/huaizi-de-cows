"""唯讀 T16 報告檢查器單元測試：拒絕缺報告、錯誤 seed 和假通過。"""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("analyze_sf16_growth", HERE / "analyze_sf16_growth.py")
analyzer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analyzer)


class SF16AnalyzerTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        for seed in (17, 41, 73):
            stem = f"growth-seed-{seed}"
            (self.directory / f"{stem}.invocation.json").write_text(
                json.dumps({"seed": seed, "source_hashes": {"ScifiConfig.gd": "verified"}}),
                encoding="utf-8",
            )
            (self.directory / f"{stem}.json").write_text(
                json.dumps({"failed": 0, "notes": ["first_win_run=4"]}),
                encoding="utf-8",
            )
            (self.directory / f"{stem}.json.snapshots.jsonl").write_text(
                json.dumps(
                    {
                        "snapshot": {
                            "player": {"hp": 66},
                            "progress": {
                                "runs": [
                                    {"victory": False, "time": 300},
                                    {"victory": False, "time": 301},
                                    {"victory": False, "time": 302},
                                    {"victory": True, "time": 570},
                                ]
                            },
                        }
                    }
                ) + "\n", encoding="utf-8"
            )

    def test_full_matrix_proven(self):
        result = analyzer.analyze(self.directory)
        self.assertEqual("PASS", result["status"])
        self.assertTrue(result["t16_compliant_full_matrix"])
        self.assertEqual(4, result["first_win_median"])

    def test_missing_report_cannot_pass(self):
        (self.directory / "growth-seed-73.json").unlink()
        result = analyzer.analyze(self.directory)
        self.assertEqual("INCOMPLETE", result["status"])
        self.assertFalse(result["t16_compliant_full_matrix"])

    def test_failed_assertion_cannot_pass(self):
        (self.directory / "growth-seed-73.json").write_text(
            json.dumps({"failed": 1, "notes": ["first_win_run=4"]}),
            encoding="utf-8"
        )
        self.assertEqual("FAIL", analyzer.analyze(self.directory)["status"])

    def test_mismatched_source_hashes_cannot_pass(self):
        (self.directory / "growth-seed-73.invocation.json").write_text(
            json.dumps({"seed": 73, "source_hashes": {"ScifiConfig.gd": "different"}}),
            encoding="utf-8"
        )
        self.assertEqual("FAIL", analyzer.analyze(self.directory)["status"])

    def test_two_early_wins_make_median_impossible(self):
        for seed in (41, 73):
            stem = f"growth-seed-{seed}"
            (self.directory / f"{stem}.json").write_text(
                json.dumps({"failed": 0, "notes": ["first_win_run=1"]}),
                encoding="utf-8",
            )
            (self.directory / f"{stem}.json.snapshots.jsonl").write_text(
                json.dumps({"snapshot": {"progress": {"runs": [{"victory": True, "time": 555}]}}}) + "\n",
                encoding="utf-8",
            )
        (self.directory / "growth-seed-17.json").unlink()
        result = analyzer.analyze(self.directory)
        self.assertEqual("FAIL", result["status"])
        self.assertTrue(result["median_3_to_5_mathematically_impossible"])


if __name__ == "__main__":
    unittest.main()
