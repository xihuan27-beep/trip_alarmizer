#!/usr/bin/env python3
"""
Import trip photos into the ChiangMaiHistory app.

For each photo in the given folder:
  1. Reads GPS coordinates from EXIF metadata (via exiftool).
  2. Finds the nearest site in sites.json.
  3. If within MATCH_RADIUS_METERS, converts the photo to JPEG, adds it as a
     new imageset under Assets.xcassets, and appends it to that site's
     "photos" array in sites.json.
  4. Photos with no GPS data, or too far from every known site, are left
     untouched and reported at the end so you can add them by hand.

Usage:
    python3 import_photos.py /path/to/photo/folder
"""

import json
import math
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
SITES_JSON = PROJECT_ROOT / "Sources/Resources/sites.json"
ASSETS_DIR = PROJECT_ROOT / "Sources/Resources/Assets.xcassets"
MATCH_RADIUS_METERS = 400
IMAGE_EXTENSIONS = {".heic", ".heif", ".jpg", ".jpeg", ".png"}


def haversine_meters(lat1, lon1, lat2, lon2):
    r = 6371000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlambda / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def read_gps(photo_paths):
    """Returns {path: (lat, lon) or None} using exiftool, batched for speed."""
    if not photo_paths:
        return {}
    cmd = ["exiftool", "-json", "-n", "-GPSLatitude", "-GPSLongitude", "-FileName", "-Directory"] + [
        str(p) for p in photo_paths
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"exiftool error: {result.stderr}", file=sys.stderr)
        return {}
    entries = json.loads(result.stdout)
    gps = {}
    for entry in entries:
        directory = entry.get("Directory", ".")
        filename = entry.get("FileName")
        full_path = Path(directory) / filename
        lat = entry.get("GPSLatitude")
        lon = entry.get("GPSLongitude")
        gps[str(full_path)] = (lat, lon) if lat is not None and lon is not None else None
    return gps


def next_photo_index(site, existing_names):
    n = 1
    while f"{site['id']}_{n}" in existing_names:
        n += 1
    return n


def add_imageset(asset_name, source_photo):
    imageset_dir = ASSETS_DIR / f"{asset_name}.imageset"
    imageset_dir.mkdir(parents=True, exist_ok=True)
    dest_jpeg = imageset_dir / f"{asset_name}.jpg"

    # sips (built into macOS) converts HEIC/PNG/etc to JPEG reliably.
    subprocess.run(
        ["sips", "-s", "format", "jpeg", str(source_photo), "--out", str(dest_jpeg)],
        capture_output=True, text=True, check=True,
    )

    contents = {
        "images": [{"filename": dest_jpeg.name, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset_dir / "Contents.json").write_text(json.dumps(contents, indent=2))


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 import_photos.py /path/to/photo/folder")
        sys.exit(1)

    folder = Path(sys.argv[1]).expanduser().resolve()
    if not folder.is_dir():
        print(f"Not a folder: {folder}")
        sys.exit(1)

    sites = json.loads(SITES_JSON.read_text())
    photos = sorted(p for p in folder.rglob("*") if p.suffix.lower() in IMAGE_EXTENSIONS)

    if not photos:
        print("No photo files found in that folder.")
        sys.exit(0)

    print(f"Found {len(photos)} photo(s). Reading GPS metadata...")
    gps_by_path = read_gps(photos)

    matched, no_gps, unmatched = [], [], []
    existing_asset_names = {p.stem for p in ASSETS_DIR.glob("*.imageset")}

    for photo in photos:
        coords = gps_by_path.get(str(photo))
        if not coords:
            no_gps.append(photo)
            continue

        lat, lon = coords
        best_site, best_dist = None, float("inf")
        for site in sites:
            d = haversine_meters(lat, lon, site["latitude"], site["longitude"])
            if d < best_dist:
                best_site, best_dist = site, d

        if best_site and best_dist <= MATCH_RADIUS_METERS:
            idx = next_photo_index(best_site, existing_asset_names)
            asset_name = f"{best_site['id']}_{idx}"
            add_imageset(asset_name, photo)
            existing_asset_names.add(asset_name)
            best_site.setdefault("photos", []).append(asset_name)
            matched.append((photo, best_site["name"], round(best_dist)))
        else:
            unmatched.append((photo, lat, lon, best_site["name"] if best_site else "?", round(best_dist)))

    SITES_JSON.write_text(json.dumps(sites, ensure_ascii=False, indent=2))

    print("\n=== 매칭된 사진 ===")
    for photo, name, dist in matched:
        print(f"  {photo.name} -> {name} ({dist}m)")

    if unmatched:
        print("\n=== 매칭 안 된 사진 (가까운 장소가 너무 멀어요) ===")
        for photo, lat, lon, nearest, dist in unmatched:
            print(f"  {photo.name}: 좌표 ({lat}, {lon}) — 가장 가까운 곳 '{nearest}'까지 {dist}m")

    if no_gps:
        print("\n=== GPS 정보 없는 사진 ===")
        for photo in no_gps:
            print(f"  {photo.name}")

    print(f"\n총 {len(matched)}장 매칭, {len(unmatched)}장 미매칭, {len(no_gps)}장 GPS 없음.")
    if matched:
        print("\nsites.json이 업데이트됐습니다. 다음 명령으로 프로젝트를 갱신하고 빌드하세요:")
        print("  xcodegen generate")


if __name__ == "__main__":
    main()
