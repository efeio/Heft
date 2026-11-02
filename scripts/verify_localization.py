#!/usr/bin/env python3
import json
import os
import subprocess
import sys

def check_string_catalog(path):
    print(f"Checking string catalog: {path}")
    if not os.path.exists(path):
        print(f"FAIL: File does not exist: {path}")
        return False

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    strings = data.get("strings", {})
    if not strings:
        print(f"FAIL: No strings found in {path}")
        return False

    missing_tr = []
    missing_en = []
    untranslated = []

    for key, val in strings.items():
        locs = val.get("localizations", {})
        if "tr" not in locs:
            missing_tr.append(key)
        else:
            unit = locs["tr"].get("stringUnit", {})
            if unit.get("state") != "translated":
                untranslated.append((key, "tr", unit.get("state")))

        if "en" not in locs:
            missing_en.append(key)
        else:
            unit = locs["en"].get("stringUnit", {})
            if unit.get("state") != "translated":
                untranslated.append((key, "en", unit.get("state")))

    if missing_tr:
        print(f"FAIL: {len(missing_tr)} keys missing TR localization")
        return False
    if missing_en:
        print(f"FAIL: {len(missing_en)} keys missing EN localization")
        return False
    if untranslated:
        print(f"FAIL: {len(untranslated)} keys are not in 'translated' state")
        return False

    print(f"PASS: All {len(strings)} keys have 100% complete 'tr' and 'en' translations with state: 'translated'.")
    return True

def check_no_hardcoded_locale():
    print("Checking for hardcoded 'tr_TR' locales...")
    res = subprocess.run(["grep", "-rn", "tr_TR", "Heft"], capture_output=True, text=True)
    if res.returncode == 0 and res.stdout.strip():
        print(f"FAIL: Found hardcoded 'tr_TR':\n{res.stdout}")
        return False
    print("PASS: Zero instances of 'tr_TR' found in Heft.")
    return True

def verify_build(configuration):
    print(f"Verifying xcodebuild for configuration: {configuration}...")
    cmd = [
        "xcodebuild",
        "-project", "Heft.xcodeproj",
        "-scheme", "Heft",
        "-configuration", configuration,
        "-destination", "generic/platform=iOS Simulator",
        "build"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"FAIL: {configuration} build failed!\n{res.stderr[-2000:]}")
        return False
    print(f"PASS: {configuration} build succeeded.")
    return True

def main():
    ok = True
    ok = check_string_catalog("Heft/Localizable.xcstrings") and ok
    ok = check_string_catalog("Heft/InfoPlist.xcstrings") and ok
    ok = check_no_hardcoded_locale() and ok
    ok = verify_build("Debug") and ok
    ok = verify_build("Release") and ok

    if ok:
        print("\nALL LOCALIZATION & BUILD VERIFICATIONS PASSED!")
        sys.exit(0)
    else:
        print("\nVERIFICATION FAILED!")
        sys.exit(1)

if __name__ == "__main__":
    main()
