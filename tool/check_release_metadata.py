#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RELEASE_URL = "https://github.com/vaeccc/dart_simple_live/releases"


def read_pubspec_version(path: Path) -> tuple[str, int]:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*[\"']?([^\"'\s]+)", text, re.MULTILINE)
    if not match:
        raise ValueError(f"Missing version in {path}")
    raw = match.group(1)
    if "+" not in raw:
        raise ValueError(f"Expected semantic version + build number in {path}: {raw}")
    version, build = raw.split("+", 1)
    return version, int(build)


def check_component(name: str, pubspec: str, metadata: str) -> list[str]:
    errors: list[str] = []
    version, build = read_pubspec_version(ROOT / pubspec)
    data = json.loads((ROOT / metadata).read_text(encoding="utf-8"))

    if data.get("version") != version:
        errors.append(
            f"{name}: metadata version {data.get('version')} != pubspec {version}"
        )
    if data.get("version_num") != build:
        errors.append(
            f"{name}: metadata version_num {data.get('version_num')} != build {build}"
        )
    if data.get("download_url") != RELEASE_URL:
        errors.append(
            f"{name}: download_url must point to this repository's Releases"
        )
    return errors


def main() -> int:
    errors = []
    errors += check_component(
        "APP", "simple_live_app/pubspec.yaml", "assets/app_version.json"
    )
    errors += check_component(
        "TV", "simple_live_tv_app/pubspec.yaml", "assets/tv_app_version.json"
    )

    app_flutter = json.loads(
        (ROOT / "simple_live_app/.fvmrc").read_text(encoding="utf-8")
    ).get("flutter")
    tv_flutter = json.loads(
        (ROOT / "simple_live_tv_app/.fvmrc").read_text(encoding="utf-8")
    ).get("flutter")
    if app_flutter != tv_flutter:
        errors.append(
            f"Flutter toolchain mismatch: APP={app_flutter}, TV={tv_flutter}"
        )

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print("Release metadata is consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
