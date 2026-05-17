#!/usr/bin/env python3
"""Synastry + composite midpoint chart computation.

Takes two natal facts.json (from astrology_engine.py) and outputs:
- synastry: inter-aspects between Person A and Person B + house overlays
- composite: midpoint chart (planets, points, angles, houses, inter-aspects)

Usage:
  python synastry_engine.py --person-a A.json --person-b B.json \
    --person-a-name person_a --person-b-name person_b \
    --output-file out.json
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

ASPECT_SPECS = {
    "Conjunction": {"angle": 0.0, "orb": 8.0},
    "Sextile":     {"angle": 60.0, "orb": 4.0},
    "Square":      {"angle": 90.0, "orb": 6.0},
    "Trine":       {"angle": 120.0, "orb": 6.0},
    "Opposition":  {"angle": 180.0, "orb": 8.0},
    "Quincunx":    {"angle": 150.0, "orb": 3.0},
}


def normalize(lon: float) -> float:
    return lon % 360.0


def angular_distance(a: float, b: float) -> float:
    delta = abs(normalize(a) - normalize(b))
    return delta if delta <= 180.0 else 360.0 - delta


def sign_info(lon: float, retrograde: bool = False) -> Dict[str, Any]:
    lon = normalize(lon)
    idx = int(lon // 30) % 12
    return {
        "longitude": round(lon, 6),
        "sign": SIGNS[idx],
        "degree_in_sign": round(lon - idx * 30.0, 6),
        "retrograde": retrograde,
    }


def midpoint(a: float, b: float) -> float:
    """Shorter-arc midpoint between two longitudes (degrees)."""
    a = normalize(a)
    b = normalize(b)
    diff = (b - a) % 360.0
    if diff > 180.0:
        mid = (a + b) / 2.0 + 180.0
    else:
        mid = (a + b) / 2.0
    return normalize(mid)


def collect_objects(facts: Dict) -> Dict[str, Dict]:
    """Flatten planets + points + angles into one name->{longitude,...} dict."""
    out: Dict[str, Dict] = {}
    out.update(facts.get("planet_positions", {}))
    out.update(facts.get("points", {}))
    angles = facts.get("angles", {})
    if "Ascendant" in angles:
        out["Ascendant"] = angles["Ascendant"]
    if "Midheaven" in angles:
        out["Midheaven"] = angles["Midheaven"]
    return out


def compute_inter_aspects(
    objects_a: Dict[str, Dict],
    objects_b: Dict[str, Dict],
    a_label: str = "person_a",
    b_label: str = "person_b",
) -> List[Dict]:
    """All aspects from each obj in A to each obj in B (cross-product)."""
    aspects: List[Dict] = []
    for name_a, a in objects_a.items():
        if "longitude" not in a:
            continue
        for name_b, b in objects_b.items():
            if "longitude" not in b:
                continue
            delta = angular_distance(a["longitude"], b["longitude"])
            for aspect_name, spec in ASPECT_SPECS.items():
                orb = abs(delta - spec["angle"])
                if orb <= spec["orb"]:
                    aspects.append({
                        f"{a_label}_object": name_a,
                        f"{b_label}_object": name_b,
                        "type": aspect_name,
                        "exact_angle": spec["angle"],
                        "actual_angle": round(delta, 6),
                        "orb": round(orb, 6),
                    })
                    break
    aspects.sort(key=lambda x: x["orb"])
    return aspects


def place_in_houses(objects: Dict[str, Dict], houses: Dict[str, Dict]) -> Dict[str, int]:
    """For each obj, find which house in `houses` it falls into (1-12)."""
    if not houses:
        return {}
    cusps = [normalize(houses[str(i)]["cusp_longitude"]) for i in range(1, 13)]
    placements: Dict[str, int] = {}
    for name, obj in objects.items():
        if "longitude" not in obj:
            continue
        lon = normalize(obj["longitude"])
        for h in range(1, 13):
            start = cusps[h - 1]
            end = cusps[0] if h == 12 else cusps[h]
            if start < end:
                if start <= lon < end:
                    placements[name] = h
                    break
            else:  # wraps 360 -> 0
                if lon >= start or lon < end:
                    placements[name] = h
                    break
        if name not in placements:
            placements[name] = 12
    return placements


def compute_composite(facts_a: Dict, facts_b: Dict) -> Dict:
    """Composite midpoint chart: midpoint of each planet/point/angle/house cusp."""
    objects_a = collect_objects(facts_a)
    objects_b = collect_objects(facts_b)

    planet_names = list(facts_a.get("planet_positions", {}).keys())
    point_names = list(facts_a.get("points", {}).keys())
    angle_names = ["Ascendant", "Midheaven"]

    composite_planets: Dict[str, Dict] = {}
    composite_points: Dict[str, Dict] = {}
    composite_angles: Dict[str, Dict] = {}

    for name in planet_names:
        if name in objects_a and name in objects_b:
            a = objects_a[name]; b = objects_b[name]
            mid = midpoint(a["longitude"], b["longitude"])
            composite_planets[name] = sign_info(mid, retrograde=bool(a.get("retrograde")) and bool(b.get("retrograde")))

    for name in point_names:
        if name in objects_a and name in objects_b:
            a = objects_a[name]; b = objects_b[name]
            mid = midpoint(a["longitude"], b["longitude"])
            composite_points[name] = sign_info(mid, retrograde=bool(a.get("retrograde")) and bool(b.get("retrograde")))

    for name in angle_names:
        if name in objects_a and name in objects_b:
            a = objects_a[name]; b = objects_b[name]
            mid = midpoint(a["longitude"], b["longitude"])
            composite_angles[name] = sign_info(mid)

    # Composite house cusps: midpoint of corresponding cusps
    houses_a = facts_a.get("houses", {})
    houses_b = facts_b.get("houses", {})
    composite_houses: Dict[str, Dict] = {}
    if houses_a and houses_b:
        for i in range(1, 13):
            ca = houses_a[str(i)]["cusp_longitude"]
            cb = houses_b[str(i)]["cusp_longitude"]
            composite_houses[str(i)] = sign_info(midpoint(ca, cb))
            composite_houses[str(i)]["cusp_longitude"] = composite_houses[str(i)]["longitude"]

    # Inter-aspects within the composite chart itself
    comp_objects: Dict[str, Dict] = {}
    comp_objects.update(composite_planets)
    comp_objects.update(composite_points)
    comp_objects.update(composite_angles)

    raw = compute_inter_aspects(comp_objects, comp_objects, "object1", "object2")
    seen = set()
    composite_aspects: List[Dict] = []
    for a in raw:
        o1, o2 = a["object1_object"], a["object2_object"]
        if o1 == o2:
            continue
        key = tuple(sorted([o1, o2]))
        if key in seen:
            continue
        seen.add(key)
        composite_aspects.append({
            "object1": o1,
            "object2": o2,
            "type": a["type"],
            "exact_angle": a["exact_angle"],
            "actual_angle": a["actual_angle"],
            "orb": a["orb"],
        })

    composite_house_placement = place_in_houses(comp_objects, composite_houses)

    return {
        "planet_positions": composite_planets,
        "points": composite_points,
        "angles": composite_angles,
        "houses": composite_houses,
        "house_placement": composite_house_placement,
        "aspects": composite_aspects,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Synastry + composite chart computation.")
    parser.add_argument("--person-a", required=True, help="path to person A natal facts.json")
    parser.add_argument("--person-b", required=True, help="path to person B natal facts.json")
    parser.add_argument("--person-a-name", default="A")
    parser.add_argument("--person-b-name", default="B")
    parser.add_argument("--output-file", required=True)
    args = parser.parse_args()

    facts_a = json.loads(Path(args.person_a).read_text(encoding="utf-8"))
    facts_b = json.loads(Path(args.person_b).read_text(encoding="utf-8"))

    objects_a = collect_objects(facts_a)
    objects_b = collect_objects(facts_b)

    a_key = args.person_a_name
    b_key = args.person_b_name

    synastry_aspects = compute_inter_aspects(objects_a, objects_b, a_key, b_key)
    a_in_b = place_in_houses(objects_a, facts_b.get("houses", {}))
    b_in_a = place_in_houses(objects_b, facts_a.get("houses", {}))

    composite = compute_composite(facts_a, facts_b)

    out = {
        "meta": {
            "person_a_name": a_key,
            "person_b_name": b_key,
            "person_a_source": args.person_a,
            "person_b_source": args.person_b,
        },
        "synastry": {
            "aspects": synastry_aspects,
            f"{a_key}_in_{b_key}_houses": a_in_b,
            f"{b_key}_in_{a_key}_houses": b_in_a,
        },
        "composite": composite,
    }

    Path(args.output_file).write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"[ok] synastry+composite written to {args.output_file}")


if __name__ == "__main__":
    main()
