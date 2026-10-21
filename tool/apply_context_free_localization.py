# -*- coding: utf-8 -*-
"""Switches the context-free `l10n` references to the `appL10n()` helper.

Services, controllers and data sources have no `BuildContext`, but they still
produce text a user reads — a notification title, an error message. They use
`appL10n()` instead of `AppLocalizations.of(context)`.

    python tool/apply_context_free_localization.py
"""

import io
import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# file -> (import path relative to the file, [replacements])
TARGETS = {
    "lib/app/config/app_config.dart": (
        "../localization/l10n.dart",
        [("l10n.versionUnsupported", "appL10n().versionUnsupported")],
    ),
    "lib/core/notifications/local_notification_service.dart": (
        "../../app/localization/l10n.dart",
        [
            ("l10n.notificationDailyTitle", "appL10n().notificationDailyTitle"),
            ("l10n.notificationDailyBody", "appL10n().notificationDailyBody"),
        ],
    ),
    "lib/features/home/data/datasources/home_remote_data_source.dart": (
        "../../../../app/localization/l10n.dart",
        [("l10n.homeDashboardUnreachable", "appL10n().homeDashboardUnreachable")],
    ),
    "lib/features/quiz/data/datasources/quiz_local_data_source.dart": (
        "../../../../app/localization/l10n.dart",
        [("l10n.quizOfflinePractice", "appL10n().quizOfflinePractice")],
    ),
    "lib/features/quiz/data/datasources/quiz_remote_data_source.dart": (
        "../../../../app/localization/l10n.dart",
        [("l10n.quiz", "appL10n().quiz")],
    ),
    "lib/features/quiz/presentation/controllers/quiz_controller.dart": (
        "../../../../app/localization/l10n.dart",
        [("l10n.quizFinishFailed", "appL10n().quizFinishFailed")],
    ),
}


def read_source(path):
    with io.open(path, "rb") as fh:
        raw = fh.read()
    has_bom = raw[:3] == b"\xef\xbb\xbf"
    encoding = "utf-8-sig" if has_bom else "utf-8"
    with io.open(path, encoding=encoding, newline="") as fh:
        return fh.read(), encoding


def add_import(source, relative):
    if "localization/l10n.dart" in source:
        return source
    statement = "import '%s';" % relative
    imports = list(re.finditer(r"^import .*?;$", source, re.MULTILINE))
    if imports:
        last = imports[-1]
        return source[: last.end()] + "\n" + statement + source[last.end():]
    match = re.search(r"^(library;|import |part )", source, re.MULTILINE)
    if match:
        return source[: match.start()] + statement + "\n\n" + source[match.start():]
    return statement + "\n\n" + source


def main():
    for file, (relative, replacements) in TARGETS.items():
        path = os.path.join(BASE, file.replace("/", os.sep))
        source, encoding = read_source(path)
        for old, new in replacements:
            if old not in source:
                raise SystemExit("not found in %s: %s" % (file, old))
            source = source.replace(old, new)
        source = add_import(source, relative)
        with io.open(path, "w", encoding=encoding, newline="") as fh:
            fh.write(source)
        print("updated %s (%d replacements)" % (file, len(replacements)))


if __name__ == "__main__":
    main()
