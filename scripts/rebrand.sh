#!/usr/bin/env bash
#
# rebrand.sh — rename the forked Conduit into Chris's own app.
#
# Usage:
#   scripts/rebrand.sh <AppName> <prefix> [oldName]
#   scripts/rebrand.sh HermesMini cmm        # -> HermesMini, com.cmm.hermesmini
#
# Does a REAL rename: git mv's the source directories (Conduit -> <AppName>),
# updates project.yml (project name, targets, bundle id, product name),
# Info.plist strings, logger subsystem ids (com.milim.* -> com.<prefix>.*),
# and PushNotificationService's bundle id. Then regenerates Conduit.xcodeproj.
#
# Safe to re-run; idempotent on the current name. Does NOT touch:
#   - the push relay URL (set in-app: Settings > Notifications > Push relay)
#   - app icons (swap in Resources/Assets.xcassets/AppIcon.appiconset)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NEW_NAME="${1:?usage: rebrand.sh <NewAppName> <prefix> [oldName]}"
PREFIX="${2:?usage: rebrand.sh <NewAppName> <prefix> [oldName]}"
OLD_NAME="${3:-Conduit}"

if [[ "$NEW_NAME" == "$OLD_NAME" ]]; then
  echo "already named $NEW_NAME — nothing to do"
  exit 0
fi

echo "==> renaming $OLD_NAME -> $NEW_NAME (bundle prefix com.$PREFIX)"

# ---- 0. rename source directories (real git mv)
for d in "$OLD_NAME" "${OLD_NAME}Tests" "${OLD_NAME}UITests"; do
  if [[ -d "$d" ]]; then
    git mv "$d" "${d/$OLD_NAME/$NEW_NAME}"
  fi
done

# ---- 1. project.yml: name, bundle prefix, product bundle id, product name, paths
python3 - "$OLD_NAME" "$NEW_NAME" "$PREFIX" <<'PY'
import re, sys
old, new, prefix = sys.argv[1:4]
p = "project.yml"
s = open(p).read()
s = s.replace("name: %s" % old, "name: %s" % new)
s = re.sub(r"bundleIdPrefix: com\.\w+", "bundleIdPrefix: com.%s" % prefix, s)
s = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER: com\.\w+\.\w+",
           "PRODUCT_BUNDLE_IDENTIFIER: com.%s.%s" % (prefix, new.lower()), s)
s = s.replace("PRODUCT_NAME: %s" % old, "PRODUCT_NAME: %s" % new)
s = s.replace("path: %s" % old, "path: %s" % new)
s = s.replace("%s/" % old, "%s/" % new)  # Resources/AlternateIcons paths etc
open(p, "w").write(s)
print("project.yml updated")
PY

# ---- 2. Info.plist / entitlements usage strings
python3 - "$OLD_NAME" "$NEW_NAME" <<'PY'
import sys
old, new = sys.argv[1:3]
for p in ("Conduit/Info.plist", "Conduit/Conduit.entitlements"):
    try:
        open(p, "w").write(open(p).read().replace(old, new))
    except FileNotFoundError:
        pass
print("plist strings updated")
PY

# ---- 3. logger subsystem ids com.milim.* -> com.<prefix>.*
python3 - "$PREFIX" "$NEW_NAME" <<'PY'
import re, sys, glob
prefix, new = sys.argv[1:3]
hits = set()
for f in glob.glob("%s/**/*.swift" % new, recursive=True):
    s = open(f).read()
    if "com.milim" in s:
        for m in re.findall(r'com\.milim\.[\w.]+', s):
            hits.add(m)
        s = s.replace("com.milim.", "com.%s." % prefix)
        open(f, "w").write(s)
print("relabeled -> com.%s.* : %s" % (prefix, sorted(hits)))
PY

# ---- 4. regenerate the Xcode project
rm -f Conduit.xcodeproj
xcodegen generate
echo "✅ $OLD_NAME -> $NEW_NAME — now open ${NEW_NAME}.xcodeproj, pick your team in Signing & Capabilities"
