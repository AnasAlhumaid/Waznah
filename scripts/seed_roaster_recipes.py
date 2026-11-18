#!/usr/bin/env python3
"""Upload the curated Sulalat roaster recipes to Firestore `recipes` (Community).

Uses the Firestore REST API with your gcloud credentials (IAM, so security
rules don't apply). Document IDs are fixed, so re-running updates in place
instead of creating duplicates.

xBloom share links are fields on these same recipe documents
(`xbloomStudioURL`, `xbloomOriginalURL`), not Remote Config. Paste them in
`XBLOOM` below and re-run with --write. The app reads them on the next fetch,
including bag-QR and App Clip opens, with no app release.

    gcloud auth login            # with the account that owns waznah-60781
    python3 scripts/seed_roaster_recipes.py            # dry run
    python3 scripts/seed_roaster_recipes.py --write    # upload
"""

import json
import re
import subprocess
import sys
import urllib.parse
import urllib.request

PROJECT = "waznah-60781"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
OWNER_UID = "waznah-curated"

BLOOM = "ترطيب (Bloom)"
WHOLE = "صب على كامل القهوة"
AROUND = "صب حول المركز"
EDGES = "صب على الأطراف"
CENTER = "صب في المنتصف"

# (id, roastery, method, coffee g, water ml, ratio, temp °C, grind, [(step, pour ml, seconds)])
RECIPES = [
    ("sulalat-alraheeq-v60", "سلالات · الرحيق (السعودية، جازان)", "V60", 18, 270, "1:15", 93, "متوسط ناعم",
     [(BLOOM, 40, 40), (WHOLE, 120, 30), (AROUND, 70, 30), (CENTER, 40, 25)]),
    ("sulalat-halo-beriti-v60", "سلالات · هالو بريتي (إثيوبيا)", "V60", 19, 280, "1:14.7", 93, "متوسط ناعم",
     [(BLOOM, 40, 40), (WHOLE, 110, 30), (EDGES, 40, 30), (CENTER, 90, 40)]),
    ("sulalat-chelchele-v60", "سلالات · شلشلي (إثيوبيا)", "V60", 22, 330, "1:15", 94, "متوسط ناعم",
     [(BLOOM, 50, 40), (WHOLE, 150, 55), (AROUND, 80, 35), (CENTER, 50, 50)]),
    ("sulalat-chelchele-chemex", "سلالات · شلشلي (إثيوبيا)", "Chemex", 20, 325, "1:16", 95, "متوسط",
     [(BLOOM, 50, 35), (WHOLE, 150, 55), (AROUND, 80, 35), (CENTER, 45, 55)]),
    ("sulalat-tico-pepe-v60", "سلالات · تيكو بيبي (كولومبيا)", "V60", 19, 285, "1:15", 94, "متوسط ناعم",
     [(BLOOM, 40, 40), (WHOLE, 140, 30), (AROUND, 60, 25), (CENTER, 45, 45)]),
    ("sulalat-el-tirra-v60", "سلالات · إل تيرا (كوستاريكا)", "V60", 18, 275, "1:15", 93, "متوسط ناعم",
     [(BLOOM, 40, 40), (WHOLE, 120, 30), (EDGES, 70, 30), (CENTER, 45, 50)]),

    # Waznah-suggested recipes for Camel Step crops (the roaster publishes crop details, not recipes).
    # Labelled "مقترح وزنة" so they're never presented as the roaster's own recipe.
    # Washed → a bit hotter, 1:16 for clarity; natural/anaerobic/carbonic → cooler, 1:15 to keep fruit sweetness.
    ("waznah-camelstep-guatemala-rojo-v60", "غواتيمالا روهو، مغسولة · مقترح وزنة (خطوة جمل)", "V60", 18, 290, "1:16", 94, "متوسط ناعم",
     [(BLOOM, 40, 40), (WHOLE, 110, 30), (AROUND, 70, 30), (CENTER, 70, 45)]),
    ("waznah-camelstep-colombia-las-palmas-v60", "كولومبيا لاس بالماس، مغسولة · مقترح وزنة (خطوة جمل)", "V60", 18, 290, "1:16", 94, "متوسط ناعم",
     [(BLOOM, 40, 40), (WHOLE, 110, 30), (AROUND, 70, 30), (CENTER, 70, 45)]),
    ("waznah-camelstep-costa-rica-paratela-v60", "كوستاريكا باراتيلا، مجففة · مقترح وزنة (خطوة جمل)", "V60", 18, 270, "1:15", 93, "متوسط ناعم",
     [(BLOOM, 40, 45), (WHOLE, 120, 30), (EDGES, 70, 30), (CENTER, 40, 40)]),
    ("waznah-camelstep-rwanda-nyiura-v60", "رواندا نيورا، لاهوائية · مقترح وزنة (خطوة جمل)", "V60", 18, 270, "1:15", 91, "متوسط",
     [(BLOOM, 40, 45), (WHOLE, 120, 30), (EDGES, 70, 30), (CENTER, 40, 40)]),
    ("waznah-camelstep-ethiopia-anasora-v60", "إثيوبيا أناسورا، كاربونيك · مقترح وزنة (خطوة جمل)", "V60", 18, 270, "1:15", 92, "متوسط ناعم",
     [(BLOOM, 40, 45), (WHOLE, 110, 30), (AROUND, 60, 30), (CENTER, 60, 40)]),
]


# Structured crop info (new optional fields). `rostery` above stays unchanged so
# already-released app versions keep showing the same title.
SULALAT, CAMEL = "سلالات", "خطوة جمل"
META = {
    "sulalat-alraheeq-v60": ("الرحيق", SULALAT, "السعودية · جازان، جبال الحشر", "مجففة · تيبيكا", "كشمش أسود، كرز، لافندر", "official"),
    "sulalat-halo-beriti-v60": ("هالو بريتي", SULALAT, "إثيوبيا · قوجي", "مجففة · ديغا", "توت أحمر، مانجو، برتقال، لافندر", "official"),
    "sulalat-chelchele-v60": ("شلشلي", SULALAT, "إثيوبيا · يرقاتشيفي", "مجففة · هيرلوم", "كرز، خوخ، ياسمين", "official"),
    "sulalat-chelchele-chemex": ("شلشلي", SULALAT, "إثيوبيا · يرقاتشيفي", "مجففة · هيرلوم", "كرز، خوخ، ياسمين", "official"),
    "sulalat-tico-pepe-v60": ("تيكو بيبي", SULALAT, "كولومبيا · توليما", "تخمير مطوّل · كاتورا", "فواكه استوائية، عنب، زهر البرتقال", "official"),
    "sulalat-el-tirra-v60": ("إل تيرا", SULALAT, "كوستاريكا · سان خوسيه", "عسلية · كاتورا", "توت أزرق، كرز، عنب أحمر", "official"),
    "waznah-camelstep-guatemala-rojo-v60": ("غواتيمالا روهو", CAMEL, "غواتيمالا · هويهويتينانغو", "مغسولة", "خوخ، لوز محمص، شوكولاتة", "waznah"),
    "waznah-camelstep-colombia-las-palmas-v60": ("كولومبيا لاس بالماس", CAMEL, "كولومبيا · ويلا", "مغسولة · كاستيلو", "كراميل، فانيلا، تفاح، ياسمين", "waznah"),
    "waznah-camelstep-costa-rica-paratela-v60": ("كوستاريكا باراتيلا", CAMEL, "كوستاريكا · لوس سانتوس", "مجففة · كاتواي، كاتورا", "فراولة، توت، مكسرات، زهور", "waznah"),
    "waznah-camelstep-rwanda-nyiura-v60": ("رواندا نيورا", CAMEL, "رواندا · نيونغوي", "لاهوائية · بوربون أحمر", "فراولة، جوافة، تين، بندق", "waznah"),
    "waznah-camelstep-ethiopia-anasora-v60": ("إثيوبيا أناسورا", CAMEL, "إثيوبيا · قوجي", "كاربونيك · هيرلوم", "زبيب، فراولة، كاجو، زهور", "waznah"),
}

# Official xBloom share links (https://share-h5.xbloom.com/?id=…).
# Create the recipe in the xBloom app, tap share, and paste the link here.
# Studio and Original are separate because their grind settings differ.
# Leave a side as "" to clear that link. Omit a recipe id to leave its stored
# links untouched, so a console edit is not wiped by the next seed.
#
# Keep percent-encoding exactly. The id is base64, so "/" and "=" arrive as
# %2F and %3D. Decoding or quoting them again makes the page fail.
# Real example (Christopher Feran — do not attach it to another crop):
#   https://share-h5.xbloom.com/?id=9EvH9mTldI3NaCM1NJX%2FCw%3D%3D
XBLOOM = {
    # "sulalat-alraheeq-v60": {
    #     "studio": "https://share-h5.xbloom.com/?id=9EvH9mTldI3NaCM1NJX%2FCw%3D%3D",
    #     "original": "",
    # },
}

SAMPLE_XBLOOM = "https://share-h5.xbloom.com/?id=9EvH9mTldI3NaCM1NJX%2FCw%3D%3D"
XBLOOM_RE = re.compile(
    r"^https://share-h5\.xbloom\.com/\?((?:[^=&#]+=[^&#]*&)*)id=[^&#\s]+((?:&[^=&#]+=[^&#]*)*)$"
)


def keywords(*values):
    """Mirror FirestoreManager.searchKeywords: lowercase, split on non-alphanumerics, unique."""
    seen, out = set(), []
    for v in values:
        for part in re.split(r"[^\w]+", v.lower()):
            part = part.replace("_", "")
            if part and part not in seen:
                seen.add(part)
                out.append(part)
    return out


def s(v):
    return {"stringValue": str(v)}


def preserved_xbloom(raw):
    """Return the link unchanged, or '' when it is blank. Reject anything else.

    urllib.parse.quote/unquote would turn %2F into / or %252F. Neither loads.
    """
    raw = (raw or "").strip()
    if not raw:
        return ""
    parsed = urllib.parse.urlparse(raw)
    if parsed.scheme != "https" or (parsed.hostname or "").lower() != "share-h5.xbloom.com":
        raise SystemExit(f"xBloom link host must be https://share-h5.xbloom.com/?id=… : {raw}")
    if parsed.path not in ("", "/"):
        raise SystemExit(f"xBloom link must not have a path: {raw}")
    if not XBLOOM_RE.match(raw):
        raise SystemExit(f"xBloom link must look like https://share-h5.xbloom.com/?id=… : {raw}")
    return raw


def check_sample_link():
    exact = preserved_xbloom(SAMPLE_XBLOOM)
    if exact != SAMPLE_XBLOOM or "%2F" not in exact or "%3D" not in exact:
        raise SystemExit("sample xBloom link was rewritten")
    if "%252F" in exact or "%253D" in exact:
        raise SystemExit("sample xBloom link was double-encoded")
    dumped = json.dumps({"stringValue": exact})
    if SAMPLE_XBLOOM not in dumped or "%252F" in dumped:
        raise SystemExit("JSON changed the sample xBloom link")


def document(doc_id, roastery, tool, coffee, water, ratio, temp, grind, steps):
    fields = {
        "id": s(doc_id),
        "ownerUid": s(OWNER_UID),
        "visibility": s("public"),
        "likeCount": {"integerValue": "0"},
        "rostery": s(roastery),
        "grain": s(grind),
        "waterGrams": s(water),
        "coffeeGrams": s(coffee),
        "ratio": s(ratio),
        "temp": s(temp),
        "tool": s(tool),
        "field3": {"arrayValue": {"values": [
            {"mapValue": {"fields": {"step": s(t), "time": s(sec), "water": s(ml)}}}
            for t, ml, sec in steps
        ]}},
        "searchKeywords": {"arrayValue": {"values": [
            s(k) for k in keywords(roastery, grind, str(water), str(coffee), ratio, str(temp), tool, "sulalat")
        ]}},
    }
    assert sum(ml for _, ml, _ in steps) == water, doc_id
    crop, roaster, origin, process, notes, source = META[doc_id]
    fields.update({"crop": s(crop), "roaster": s(roaster), "origin": s(origin),
                   "process": s(process), "tastingNotes": s(notes), "source": s(source)})
    fields["searchKeywords"]["arrayValue"]["values"] += [
        s(k) for k in keywords(crop, roaster, origin, process, notes)
        if s(k) not in fields["searchKeywords"]["arrayValue"]["values"]]
    return fields


def apply_xbloom(doc_id, fields):
    """Fields to add, and field paths that should be deleted (in the mask, absent from fields)."""
    links = XBLOOM.get(doc_id)
    if not links:
        return
    for side, field in (("studio", "xbloomStudioURL"), ("original", "xbloomOriginalURL")):
        if side not in links:
            continue
        exact = preserved_xbloom(links[side])
        if exact:
            fields[field] = s(exact)
        else:
            fields.pop(field, None)
            # Caller adds `field` to the update mask so Firestore deletes it.


def main():
    check_sample_link()
    write = "--write" in sys.argv
    writes = []
    for doc_id, roastery, tool, coffee, water, ratio, temp, grind, steps in RECIPES:
        fields = document(doc_id, roastery, tool, coffee, water, ratio, temp, grind, steps)
        # likeCount is left out of the update mask so re-runs keep existing likes.
        mask = [k for k in fields if k != "likeCount"]
        links = XBLOOM.get(doc_id) or {}
        apply_xbloom(doc_id, fields)
        for side, field in (("studio", "xbloomStudioURL"), ("original", "xbloomOriginalURL")):
            if side in links and field not in mask:
                # Present in the mask and absent from fields deletes a cleared link.
                mask.append(field)
        writes.append({
            "update": {"name": f"projects/{PROJECT}/databases/(default)/documents/recipes/{doc_id}", "fields": fields},
            "updateMask": {"fieldPaths": mask},
            "updateTransforms": [{"fieldPath": "updatedAt", "setToServerValue": "REQUEST_TIME"}],
        })
        print(f"{'WRITE' if write else 'DRY  '} recipes/{doc_id}: {roastery} · {tool} · {coffee}g/{water}ml")

    if not write:
        print("\nDry run only. Re-run with --write to upload.")
        return

    token = subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()

    # Create docs that don't exist yet with likeCount 0 + createdAt (so they sort as newest).
    for w in writes:
        name = w["update"]["name"]
        req = urllib.request.Request(f"https://firestore.googleapis.com/v1/{name}", headers={"Authorization": f"Bearer {token}"})
        try:
            urllib.request.urlopen(req)
        except urllib.error.HTTPError as e:
            if e.code == 403:
                account = subprocess.check_output(["gcloud", "config", "get-value", "account"], text=True).strip()
                sys.exit(f"\n403: {account} has no access to {PROJECT}. Run `gcloud auth login` with the project owner's account.")
            if e.code != 404:
                raise
            w["updateMask"]["fieldPaths"].append("likeCount")
            w["updateTransforms"].append({"fieldPath": "createdAt", "setToServerValue": "REQUEST_TIME"})

    body = json.dumps({"writes": writes}).encode()
    req = urllib.request.Request(
        f"{BASE}:commit", data=body, method="POST",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        result = json.load(resp)
    print(f"\nUploaded {len(result.get('writeResults', []))} recipes to {PROJECT}/recipes.")


if __name__ == "__main__":
    main()
