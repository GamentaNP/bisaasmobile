# -*- coding: utf-8 -*-
"""Audits the translated copy for mechanical defects.

A machine-written translation can be *understandable* and still be wrong in
ways a user notices: the same English term spelled two different ways in
two screens, a nukta on one occurrence and not on the next, half a
sentence left in English.

This checks the things that can be checked mechanically:

  1. **Terminology drift** — the same term transliterated two different
     ways. `streak` as स्ट्रीक in one screen and स्ट्रिक in the next is the
     kind of thing that makes an app feel machine-made.
  2. **Partial translation** — a Devanagari message with a real English
     word left in the middle of it.
  3. **Nukta drift** — क्विज़ in one message and क्विज in the next.

    python tool/audit_translations.py
"""

import collections
import io
import json
import os
import re
import sys

BASE = r"C:\laragon\www\bisaasmobile"
ARB = os.path.join(BASE, "lib", "l10n")

DEVANAGARI = re.compile(r"[\u0900-\u097F]")
# A word that is not a placeholder and not an allowed acronym.
LATIN_WORD = re.compile(r"\b([A-Za-z]{2,})\b")
PLACEHOLDER = re.compile(r"\{[a-zA-Z_]+\}")
URL_OR_EMAIL = re.compile(r"(https?://\S+|[\w.+-]+@[\w.-]+)")

ALLOWED_LATIN = {
    # acronyms and units
    "XP", "AI", "API", "MP", "PM", "MB", "KB", "GB", "MPa", "kPa", "kN",
    "UI", "URL", "MCQ", "MCQs", "PSC", "EICE", "FSRS", "DELETE",
    # product, organisation and place names
    "CivilCal", "BiSaaS", "Bisaas", "Civil", "Loksewa", "Nepal", "Elite",
    "Quiz", "Google", "Apple",
    # API field, endpoint and service names, which are wire values
    "credits", "description", "metadata", "source", "library", "api", "download",
    "MasteryService", "computeReadiness", "Goal", "ID", "Tracks", "Laravel",
    "civil", "psc", "SRS", "id", "levelling", "RCC", "Bernoulli",
}

# Transliterations that must be spelled the same way everywhere.
TERMS = {
    "streak": ("स्ट्रीक", "स्ट्रिक"),
    "quiz": ("क्विज़", "क्विज", "क्विज़"),
    "offline": ("ऑफ़लाइन", "ऑफलाइन", "ओफलाइन", "ओफ़लाइन"),
    "online": ("ऑनलाइन", "ओनलाइन"),
    "coins": ("क्विन", "क्विन"),
    "coins_hi": ("कॉइन", "कोइन"),
    "calculator": ("क्यालकुलेटर", "कैलकुलेटर"),
    "streak_hi": ("स्ट्रीक", "स्ट्रिक"),
    "review": ("समीक्षा", "समिक्षा"),
    "leaderboard": ("लिडरबोर्ड", "लीडरबोर्ड"),
}


def load(locale):
    with io.open(os.path.join(ARB, "app_%s.arb" % locale), encoding="utf-8") as fh:
        data = json.load(fh)
    return {k: v for k, v in data.items() if not k.startswith("@")}


def latin_words(text):
    """The Latin words in a message that are not copy.

    A placeholder, an email address and a URL are removed first: none of
    them is untranslated prose.
    """
    stripped = PLACEHOLDER.sub(" ", text)
    stripped = URL_OR_EMAIL.sub(" ", stripped)
    return set(LATIN_WORD.findall(stripped))


def main():
    english = load("en")
    failed = False

    for locale in ("ne", "hi"):
        data = load(locale)
        print("=== %s ===" % locale)

        # 1. Partial translation: a real English word inside Devanagari.
        partial = []
        for key, value in data.items():
            if not DEVANAGARI.search(value):
                continue
            for word in latin_words(value):
                if word in ALLOWED_LATIN:
                    continue
                partial.append((key, word, value))
        if partial:
            failed = True
            print("  partially translated: %d" % len(partial))
            for entry in partial[:20]:
                print("    %s: %s" % (entry[0], entry[2]))
        else:
            print("  partially translated: 0")

        # 2. Terminology drift: the same English term, two spellings.
        #    The check is a regex, not a substring test: `क्विज` is a prefix
        #    of `क्विज़`, so a substring test reports a drift that is not
        #    there.
        for label, variants in TERMS.items():
            present = set()
            for value in data.values():
                for variant in variants:
                    if re.search(re.escape(variant) + r"(?!़)", value):
                        present.add(variant)
            if len(present) > 1:
                failed = True
                print("  DRIFT %-14s %s" % (label, sorted(present)))

        # 3. Nukta drift: the same base with and without the nukta.
        bases = collections.defaultdict(set)
        for value in data.values():
            for token in re.findall(r"[\u0900-\u097F\u095E]+", value):
                base = token.replace("\u095E", "")
                if base != token:
                    bases[base].add(token)
        drifts = {b: sorted(v) for b, v in bases.items() if len(v) > 1}
        if drifts:
            failed = True
            print("  NUKTA DRIFT:")
            for base, variants in sorted(drifts.items()):
                print("    %s -> %s" % (base, variants))
        else:
            print("  nukta drift: none")

        # 4. A message that is entirely Latin in a translated locale.
        for key, value in data.items():
            if DEVANAGARI.search(value):
                continue
            if value == english.get(key):
                continue
            if latin_words(value) - ALLOWED_LATIN:
                failed = True
                print("  NOT TRANSLATED %s: %s" % (key, value))

    if failed:
        print("\nFAIL: the translated copy has mechanical defects")
        sys.exit(1)
    print("\nOK: no mechanical defects found")


if __name__ == "__main__":
    main()
