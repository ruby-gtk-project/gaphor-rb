# Translation parity — gaphor-rb

| | |
|---|---|
| Upstream | `main` @ `b7a3a5f76` (unchanged since prior round) |
| Port | `ruby` @ `69034776` |
| Upstream msgids (`po/gaphor.pot`) | 750 |
| Upstream locales shipped | 25 (`be ca cs de es fi fr gl hi hr hu it ja ko nl pl pt_BR ru sl sv ta tr uk vi zh_Hans`) + `.pot` |
| Port msgids | 0 |
| Port locales | 0 |
| Gaps | 750 keys, 25 languages |

## Census

`po/gaphor.pot` on `origin/main`: `grep -c '^msgid "' po/gaphor.pot` → **750**.
These come from `_()`/`C_()`/`N_()` calls across `gaphor/**/*.py` and
`translatable="yes"` attributes across the 26 `.ui` files, extracted by
upstream's own `xgettext`/Babel pipeline (`po/babel.ini`).

Port: `grep -rn '_("' lib/` and the equivalent for `gettext(`, `N_(`, `n_(`
across `lib/`, `exe/gaphor` → **zero matches of any kind**. There is no
`require 'gettext'`, no `GetText.bindtextdomain`, no `po/` directory, no
`.pot` file, nothing that could be extracted into a catalogue. Confirmed by
direct read of every file in `lib/gaphor/`: `about_dialog.rb`,
`action.rb`, `action_group.rb`, `application.rb`, `debug_info.rb`,
`preferences_dialog.rb`, `settings.rb`, `shortcuts_dialog.rb`, `styling.rb`,
and, re-checked this round for the seven files added since the prior audit,
`error_dialog.rb`, `file_dialog.rb`, `in_app_notifier.rb`, `menu_fragment.rb`,
`recent_files.rb`, `status_window.rb`, `text_field.rb` — all seven are
equally clean of any gettext marker, so the zero-infrastructure finding has
not narrowed at all despite the port tripling in file count.

## What that means concretely, for the one unit the port built

Every user-visible string in the application-shell unit is a bare Ruby
literal:

- `lib/gaphor/application.rb`: `"Gaphor"` (window title), `"Main Menu"`
  (tooltip), `"_Preferences"`, `"_Keyboard Shortcuts"`, `"_Help"`,
  `"_About Gaphor"` (menu items — upstream's `greeter.ui`/`menubar.ui` mark
  the equivalent strings `translatable="yes"`), `"The modeling core has not
  been ported yet…"` (status page, port-only text, see
  `ACCOUNTABILITY_ENSURANCE.md`).
- `lib/gaphor/debug_info.rb`: `"No errors have been intercepted. We're good."`,
  `"Errors:"`, `"Time since application startup: …"` — upstream's
  `gaphor/ui/help/debuginfo.py` runs these through gettext; the port's do not
  go through anything.
- This round's additions carry the same pattern: `lib/gaphor/error_dialog.rb`'s
  `"Close"` and `"Start Debug Session"` response labels, `lib/gaphor/
  file_dialog.rb`'s `"Gaphor Models"` and `"All Files"` filter names — all
  bare literals, none marked, matching `gaphor/ui/errordialog.py` and
  `gaphor/ui/filedialog.py`'s equivalent strings which upstream does run
  through gettext.
- `lib/gaphor/about_dialog.rb`, `preferences_dialog.rb`, `shortcuts_dialog.rb`:
  not individually re-enumerated here, but the same pattern holds throughout
  — confirmed by the absence of any marker function in the grep above, which
  would have caught a call in any of them.

None of these strings has a msgid. None of the 25 languages upstream ships —
including languages with completed catalogues for exactly these help-dialog
and menu strings — has anything to translate against in the port. A German or
Japanese user of the port sees English, unconditionally, regardless of their
`LANG`, because there is no `gettext` call to even consult `LANG`.

## The catalogue-level claims, each checked

1. **Key sets equal?** No. Upstream: 750. Port: 0. Not "0 minus the ones that
   don't apply" — the port has built no infrastructure to have any msgid at
   all, so the comparison is 750 vs 0 outright.
2. **Byte-identical keys?** Vacuous — there are no port keys to compare
   upstream's against.
3. **Languages ship?** No. `po/` (25 `.po` + `babel.ini` + `release_mature_
   locales.json`) was not copied, adapted, or referenced anywhere in the
   port. `gaphor-rb.gemspec` was checked for a `po/` reference or a
   `GetText` runtime dependency — none found.

## Rules check

- No msgid was reworded to match the port (there being no port msgid to have
  reworded it to).
- No gap here is recorded as closed anywhere else — `COMPONENT_PARITY.md`
  cross-references this report for the Text axis of the one unit built and
  marks every one of that unit's rows as a Text-axis gap, consistent with
  this ledger.

## Verdict

**0/750, 0/25 languages. This is a complete translation-parity failure**,
not a partial one. The port has not reached the point of having a first
msgid; this is earlier than "some strings are unmarked" — it is "no
infrastructure for marking any string exists." The port's current output is,
unconditionally, English-only software that cannot become anything else
without groundwork no file in `lib/` has started.
