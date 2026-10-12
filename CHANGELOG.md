# Changelog

## 1.1.0 — 2026-10-12

This release adapts Redcase to Redmine 6.1 and improves permissions, localization,
and documentation.

- Support Rails/Zeitwerk initialization and reloads, with reliable hook registration.
- Correct JavaScript filename casing for Linux and reuse Redmine's jQuery.
- Enforce project boundaries, issue visibility, and separate permissions for
  viewing, managing, and executing test cases.
- Fix nested execution suites, chart counts, and copying test cases between projects.
- Escape dynamic text and improve CSV/RTF exports.
- Complete German interface text and localize menus, dialogs, history, charts,
  and exports without changing stored result values or system folder identifiers.
- Provide English documentation, installation instructions, and automated
  compatibility, reload, and localization checks.

Validated with Redmine 6.1.2-stable, Rails 7.2.3, Ruby 3.3.7, and MySQL 8.4.11.
See the [validation report](doc/REDMINE_6_1_VALIDATION.md) for test coverage,
browser checks, and known limitations.
