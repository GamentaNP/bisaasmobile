# -*- coding: utf-8 -*-
"""Rewrites hardcoded UI strings to `l10n.<key>`.

Reads the machine-readable output of `tool/localization_coverage.dart --json`
and replaces each string literal with the generated localisation getter.

Three things the naive version gets wrong, all of them found the hard way:

  * **A UTF-8 BOM shifts every offset.** Dart's `readAsStringSync` strips the
    BOM, so the analyzer's offsets do not count it; Python's `utf-8` decoder
    keeps it. The file is therefore read as `utf-8-sig` and written back the
    same way, so the BOM survives and the offsets line up.

  * **A `const` chain has to go with the literal.** `const InputDecoration(
    labelText: 'Email')` becomes `const InputDecoration(labelText:
    l10n.commonEmail)`, and a getter call is not a constant expression, so
    every `const` keyword the literal sits inside has to be removed — not
    only the innermost one.

  * **A message with placeholders is a method, not a getter.** `l10n.quiz-
    ResultCorrectOf` needs its arguments, so the interpolated expressions of
    the original literal are passed through in order.

The mapping is by the English text of the literal. Where one English string
maps to more than one key (the same wording used in two places that mean
different things), the file and line are given explicitly.

    python tool/apply_localization.py --dry-run
    python tool/apply_localization.py --apply
"""

import io
import json
import os
import re
import shutil
import subprocess
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (file, line) -> key. Used where the English wording is shared but the
# meaning — and therefore the key — is not.
OVERRIDES = {
    ("lib/features/quiz/presentation/quiz_home_page.dart", 86): "quizHomeLoadError",
    ("lib/features/quiz/presentation/screens/quiz_attempt_screen.dart", 142): "quizAttemptLoadError",
    # The source capitalises "Guest"; the ARB entry is the shared one.
    ("lib/features/auth/presentation/login_page.dart", 249): "continueAsGuest",
    # The source hard-codes the total as "3" and interpolates only the step.
    ("lib/features/onboarding/presentation/screens/onboarding_screen.dart", 132): "onboardingStepOf",
    # The source pluralises inline (`mission` / `missions`), so the text does
    # not match any ARB value; the call is given explicitly below.
    ("lib/features/home/presentation/screens/home_screen.dart", 449): "homeMissionsReady",
}

# (file, line) -> the exact call to write, for the cases the argument
# mapping cannot work out on its own.
CALL_OVERRIDES = {
    (
        "lib/features/onboarding/presentation/screens/onboarding_screen.dart",
        132,
    ): "l10n.onboardingStepOf(_currentPage + 1, 3)",
    # The source pluralises inline (`mission` / `missions`). Nepali and Hindi
    # do not inflect for number, so the ARB key takes the count and the
    # English text says "missions" for both.
    (
        "lib/features/home/presentation/screens/home_screen.dart",
        449,
    ): "l10n.homeMissionsReady(claimable)",
}

# Debug-only affordances. The `kDebugMode` guard compiles them out of a
# release build, so they never reach a user and do not need a translation.
SKIP_TEXTS = {
    "⚡ Debug Auto-Login (user@bisaas.test)",
    # An email address, not copy.
    "support@bisaas.com",
    "privacy@bisaas.com",
    # The avatar fallback: the first letter of the display name.
    "C",
}

# The core journey: the screens a user walks from install to finished quiz.
#
# These are the files the app promises to deliver in the language the user
# picks. Everything else stays English for now, and the gap is measured rather
# than hidden — see `test/app/localization_coverage_test.dart`.
SCOPE = {
    # auth
    "lib/features/auth/presentation/login_page.dart",
    "lib/features/auth/presentation/screens/register_screen.dart",
    "lib/features/auth/presentation/screens/forgot_password_screen.dart",
    "lib/features/auth/presentation/screens/reset_password_screen.dart",
    "lib/features/auth/presentation/screens/splash_screen.dart",
    "lib/features/auth/presentation/widgets/social_sign_in_buttons.dart",
    "lib/features/auth/presentation/widgets/email_verification_banner.dart",
    # onboarding
    "lib/features/onboarding/presentation/screens/onboarding_screen.dart",
    # quiz
    "lib/features/quiz/presentation/quiz_home_page.dart",
    "lib/features/quiz/presentation/screens/quiz_intro_screen.dart",
    "lib/features/quiz/presentation/screens/quiz_attempt_screen.dart",
    "lib/features/quiz/presentation/screens/quiz_result_screen.dart",
    "lib/features/quiz/presentation/screens/quiz_review_screen.dart",
    "lib/features/quiz/presentation/screens/quiz_funnel_screen.dart",
    "lib/features/quiz/presentation/screens/quiz_browser_screen.dart",
    "lib/features/quiz/presentation/controllers/quiz_controller.dart",
    "lib/features/quiz/data/datasources/quiz_local_data_source.dart",
    "lib/features/quiz/data/datasources/quiz_remote_data_source.dart",
    # calculator
    "lib/features/calculator/presentation/screens/calculator_detail_screen.dart",
    "lib/features/calculator/presentation/screens/calculator_browser_screen.dart",
    "lib/features/calculator/presentation/screens/calculator_history_screen.dart",
    "lib/features/calculator/presentation/widgets/calculator_assistant_panel.dart",
    "lib/features/calculator/presentation/widgets/step_by_step_solution.dart",
    # home
    "lib/features/home/presentation/screens/home_screen.dart",
    "lib/features/home/data/datasources/home_remote_data_source.dart",
    # consent + privacy
    "lib/core/consent/consent_screens.dart",
    "lib/features/privacy/presentation/privacy_data_screen.dart",
    # notifications
    "lib/core/notifications/local_notification_service.dart",
    # app level
    "lib/app/force_update_screen.dart",
    "lib/app/maintenance_screen.dart",
    "lib/app/config/app_config.dart",
    "lib/app/router/app_router.dart",
    "lib/app/app.dart",
    # tier 2 — the daily loop
    "lib/features/profile/presentation/screens/profile_screen.dart",
    "lib/features/profile/presentation/widgets/skill_radar_chart.dart",
    "lib/features/settings/presentation/screens/settings_screen.dart",
    "lib/features/streak/presentation/screens/streak_screen.dart",
    "lib/features/streak/presentation/widgets/streak_calendar.dart",
    # tier 3 — study and AI
    "lib/features/tutor/presentation/screens/tutor_plan_screen.dart",
    "lib/features/tutor/presentation/screens/tutor_onboarding_screen.dart",
    "lib/features/tutor/presentation/screens/tutor_chat_screen.dart",
    "lib/features/ai_settings/presentation/screens/ai_usage_screen.dart",
    "lib/features/ai_settings/presentation/screens/ai_keys_screen.dart",
    "lib/features/ai_settings/presentation/controllers/ai_settings_controller.dart",
    "lib/features/practice/presentation/screens/practice_browser_screen.dart",
    "lib/features/practice/presentation/screens/practice_session_screen.dart",
    "lib/features/economy/presentation/screens/inventory_screen.dart",
    "lib/features/economy/presentation/screens/wallet_screen.dart",
    "lib/features/economy/presentation/screens/shop_screen.dart",
    "lib/features/economy/presentation/economy_screen.dart",
    "lib/features/library/presentation/screens/library_detail_screen.dart",
    "lib/features/library/presentation/screens/library_browser_screen.dart",
}


def normalise(text):
    return re.sub(r"\{[^}]*\}", "{…}", text)


def dart_executable():
    """The Dart SDK's `dart`, found through the PATH or the Flutter install."""
    found = shutil.which("dart")
    if found:
        return found
    for candidate in (
        r"C:\src\flutter\bin\dart.bat",
        r"C:\src\flutter\bin\dart.exe",
    ):
        if os.path.exists(candidate):
            return candidate
    raise SystemExit("cannot find the dart executable")


def load_arb():
    """The English ARB, for the placeholder names of each key."""
    path = os.path.join(BASE, "lib", "l10n", "app_en.arb")
    with io.open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    keys = {}
    for key, value in data.items():
        if key.startswith("@"):
            continue
        meta = data.get("@" + key, {})
        names = list(meta.get("placeholders", {}).keys())
        keys[key] = {"text": value, "placeholders": names}
    return keys


def load_hits():
    out = subprocess.run(
        [
            dart_executable(),
            "run",
            os.path.join("tool", "localization_coverage.dart"),
            "--json",
        ],
        cwd=BASE,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    start = out.stdout.find("[")
    if start == -1:
        raise SystemExit("could not parse tool output:\n%s" % out.stderr[-2000:])
    return json.loads(out.stdout[start:])


def resolve(hit, arb):
    if hit["text"] in SKIP_TEXTS:
        return None
    key = OVERRIDES.get((hit["file"], hit["line"]))
    if key:
        return key
    needle = normalise(hit["text"])
    candidates = [k for k, v in arb.items() if normalise(v["text"]) == needle]
    if len(candidates) == 1:
        return candidates[0]
    if not candidates:
        return "<<UNMAPPED:%s>>" % hit["text"]
    return "<<AMBIGUOUS:%s>>" % "/".join(candidates)


def build_call(hit, key, arb):
    """The replacement text for one literal."""
    explicit = CALL_OVERRIDES.get((hit["file"], hit["line"]))
    if explicit:
        return explicit
    placeholders = arb[key]["placeholders"]
    interpolations = hit.get("interpolations", [])
    if not placeholders:
        if interpolations:
            return "<<NEEDS-ARG:%s>>" % key
        return "l10n." + key
    if len(placeholders) != len(interpolations):
        return "<<ARG-MISMATCH:%s %d vs %d>>" % (
            key,
            len(placeholders),
            len(interpolations),
        )
    return "l10n.%s(%s)" % (key, ", ".join(interpolations))


def read_source(path):
    """The file's text, and whether it carries a UTF-8 BOM."""
    with io.open(path, "rb") as fh:
        raw = fh.read()
    has_bom = raw[:3] == b"\xef\xbb\xbf"
    encoding = "utf-8-sig" if has_bom else "utf-8"
    with io.open(path, encoding=encoding, newline="") as fh:
        return fh.read(), encoding


def main():
    apply = "--apply" in sys.argv
    only = None
    for index, argument in enumerate(sys.argv):
        if argument == "--file" and index + 1 < len(sys.argv):
            only = sys.argv[index + 1]

    arb = load_arb()
    hits = load_hits()

    problems = []
    plan = []
    for hit in hits:
        if only and only not in hit["file"]:
            continue
        if hit["file"] not in SCOPE:
            continue
        key = resolve(hit, arb)
        if key is None:
            continue
        if key.startswith("<<"):
            problems.append((hit["file"], hit["line"], hit["text"], key))
            continue
        call = build_call(hit, key, arb)
        if call.startswith("<<"):
            problems.append((hit["file"], hit["line"], hit["text"], call))
            continue
        plan.append((hit, key, call))

    print("mapped %d strings" % len(plan))
    if problems:
        print("\n%d unresolved:" % len(problems))
        for file, line, text, why in problems:
            print("  %s:%d  %s\n      %s" % (file, line, text, why))

    if not apply:
        print("\n(dry run — pass --apply to write)")
        return

    by_file = {}
    for hit, key, call in plan:
        by_file.setdefault(hit["file"], []).append((hit, key, call))

    for file, entries in by_file.items():
        path = os.path.join(BASE, file.replace("/", os.sep))
        source, encoding = read_source(path)

        # Offsets are in UTF-16 code units (the analyzer's convention), so the
        # splice happens on the UTF-16 bytes.
        raw = source.encode("utf-16-le")

        # Every edit is applied from the end of the file backwards, so the
        # offsets of the not-yet-applied edits stay valid.
        edits = []
        const_offsets = set()
        for hit, key, call in entries:
            edits.append((hit["offset"], hit["length"], call.encode("utf-16-le")))
            for const_offset in hit.get("constOffsets", []):
                const_offsets.add(const_offset)

        # A `const` keyword can enclose several literals; it is removed once.
        for const_offset in const_offsets:
            edits.append((const_offset, len("const"), b""))

        for start_units, length_units, replacement in sorted(edits, key=lambda e: e[0], reverse=True):
            start = start_units * 2
            end = (start_units + length_units) * 2
            raw = raw[:start] + replacement + raw[end:]
            # Removing `const` leaves the space that followed it, so take that
            # too — unless the keyword was followed by a newline, where the
            # indentation already separates the words. The space is one whole
            # UTF-16 code unit: taking a single *byte* would leave the buffer
            # with an odd length and the decode would fail.
            if length_units == len("const") and start + 2 <= len(raw) and raw[start : start + 2] == b" \x00":
                raw = raw[:start] + raw[start + 2 :]

        # Decode before opening the file for writing: opening truncates, so a
        # failure while building the content would leave an empty source file.
        content = raw.decode("utf-16-le")
        with io.open(path, "w", encoding=encoding, newline="") as fh:
            fh.write(content)
        print("rewrote %s (%d strings)" % (file, len(entries)))


if __name__ == "__main__":
    main()
