# Redmine 6.1 compatibility and review

Validated on 2026-10-12. Release version: `1.1.0` (tag `v1.1.0`).
Baseline: Uforia-Infotech/redcase commit `259a77575151e3cc6b37f4c3f2228fd728fe658b`.

## Environment

- Redmine 6.1.2-stable, Rails 7.2.3, Ruby 3.3.7, acts_as_tree 2.9.1.
- MySQL 8.4.11, Linux Docker container, `RAILS_ENV=development`.
- Browser: Codex integrated browser. Desktop drag-and-drop tested at 1440 × 1000.
- Existing development database backed up before plugin installation.
- All 16 original Redcase migrations completed successfully; no migration changes were required.

## Corrections and review findings addressed

- Removed obsolete `unloadable` calls and the global Kernel workaround.
- Resolve model patches through Zeitwerk on Redmine's `to_prepare` initialization.
- Keep the hook listener outside Rails autoload paths and register it once in
  each hook registry. This handles both a retained and a reloaded Redmine registry.
- Corrected case-sensitive JavaScript names and removed a hard-coded CSS digest.
- Reuse Redmine's jQuery, including jQuery UI; do not load the bundled jQuery 2.1.3.
- Generate the API base URL through Rails, including any application URL prefix.
- Use Zeitwerk-compatible exporter constants; RTF handles missing descriptions.
  Keep the bundled RTF library in `vendor` to avoid repeated constant definitions
  when Rails reloads application code.
- Scope test cases, journals, attachments, environments and suite operations to the
  authorized project. Respect private issue visibility in trees, reports and exports.
- Replace unrestricted environment mass assignment with explicit strong parameters.
- Separate execution permission from permission to rearrange test cases. Give
  execution-only users access to their trees and report controls.
- Reject cyclic suite moves and protect system test suites against deletion.
- Escape history text, link labels and tree labels. Replace generated inline
  JavaScript in the “Create Issue” button with a delegated event handler and JSON data.
- Fix membership detection for nested execution suites and graph counts for
  cases outside the selected suite. Moving within the same suite retains membership.
- Fix copying categories and versions to another project and create the copied
  issue's Redcase linkage immediately.
- Find the tracker change in the complete journal detail set and handle a missing
  test tracker. Reports and history tolerate a missing executor.
- Decode German translation entities so labels display umlauts correctly.

## Automated verification

Run from the Redmine directory in a migrated development/test installation:

```sh
bundle exec rake zeitwerk:check
bundle exec rails runner plugins/redcase/test/compatibility_smoke.rb
bundle exec rails runner plugins/redcase/test/reload_smoke.rb
```

The compatibility runner passed **57 checks**. It uses non-admin users, temporary
private projects, real Rails integration requests and database assertions. Records
created during the test are rolled back; mail delivery is disabled in that process.
Coverage includes execution persistence, page/partial rendering, nested suite
counts, private issue visibility, cross-project access rejection, parameter
filtering, executor/viewer permissions, copying with categories/versions, CSV/RTF,
missing executors and projects without versions.

The reload runner checks model associations, a single hook listener, exporter
autoloading and RTF document generation after three reloads. It isolates Redcase
initialization within its own process;
it does not modify the running application or other plugins' source.

## Browser verification

Using the non-admin `redcase61_browser` account in the separate private project
`redcase-61-test`:

1. Create a test suite and execution environment.
2. Create Test case issue **#84**, with a quoted title and German text, using
   the ordinary Redmine form; change its status from New to In Progress.
3. Expand .Unsorted and drag the case onto the root execution suite.
4. Save a Failed result with quotes, ampersand and literal HTML in the comment;
   verify that the comment displays as text.
5. Create related Bug **#85** from the failed execution.
6. Save a Passed result and verify both entries in history.
7. Select the tested environment in Report; confirm the latest result is Passed.
8. Download CSV and RTF through the browser and inspect the actual file contents.

The successful browser session had no console errors or warnings. Browser sample
records remain in the development project for inspection. Screenshots are stored
locally in `.cache/redcase/` in the containing workspace, outside this plugin repo.

## Limits and environment observations

- This validates the listed workflows and versions, rather than every plugin
  feature, database adapter, older-data migration, or production configuration.
- The existing compiled Propshaft manifest initially lacked Redcase assets.
  Assets were rebuilt and the application restarted. When editing JavaScript/CSS
  with a precompiled manifest, rebuild assets and restart, or remove the manifest
  using your development environment's normal procedure to enable live assets.
- A full reload with all currently installed plugins failed in
  `RedmineHelpdesk::Patches::SettingsControllerPatch`. An eager-load run also
  logged an unrelated UX Toolkit `Setting.plugin_redmine_custom_css` error while
  the loader check itself passed. These third-party sources were not changed.
  Redcase reload behavior is verified separately; the full application was
  restarted before the final browser validation.
- The original tracker/status name conventions remain: `Test case`, `In Progress`,
  `Obsolete`; creating bugs requires the `Bug` tracker and Redmine's `add_issues`
  permission. Existing installations should keep these exact names.
- The inherited fixed-width UI is intended for desktop use. Mobile layout,
  large datasets and a complete security audit were outside this validation.
- Validation was performed in the development system; no production deployment was performed.

## German text correction and follow-up review

- Corrected spelling and terminology, including “Vollständiger Bericht”,
  “Ausführungssuite”, “Testdurchführung” and “Ausgeführt von”.
- Localized page/menu titles, context menus, dialog titles, error/success messages,
  history headings, result selectors, graph legends, report filters, export links,
  CSV/RTF headings and the roadmap summary. Replaced English text embedded in
  export images with translated text next to a neutral icon.
- Moved translation keys into the `redcase` namespace, including the existing
  Polish and Russian labels, to prevent changes to Redmine's shared labels.
  New missing translations fall back to English.
- Preserve stored result names and suite IDs; report filters use stable values
  rather than translated option text. System suite checks use metadata rather
  than translated node labels. The editable execution-suite name retains its
  stored value when its display label is translated.
- Reviewed HTML/JSON output and escaped dynamic chart legends, tooltip subjects
  and roadmap labels. Roadmap counts now respect private issue visibility.
- Rewrote the README for this fork, including installation, configuration,
  exact tracker/status names, CSV format, tested scope, Apache-2.0 license,
  SaaS-Secure attribution and verified public UX Toolkit / SCM Creator links.
- Extended the integration runner with German page/tree/report/chart/export,
  missing-version, roadmap visibility and language fallback checks. A separate
  dependency-free Node.js runner exercises message interpolation, unknown-result
  fallback and all report filters independently of translated labels:

  ```sh
  node plugins/redcase/test/localization_smoke.js
  ```

Follow-up verification passed: **57 integration checks**, the Node.js filter and
message checks, JavaScript syntax checks, `zeitwerk:check`, three isolated reloads
and `git diff --check`. The manual review found no remaining actionable defect
within this localization/documentation change after the corrections above.

The final integrated-browser session verified German management/context menus,
the “Testsuite anlegen” dialog including “Schließen”, execution result choices,
history headings/results and the “Fehler melden” button. The “Nicht bestanden”
filter hid the passed case and “Bestanden” showed it again. CSV/RTF files were
downloaded and their German contents inspected. The final session had no console
errors or warnings. Screenshots: `.cache/redcase/browser-german-report.png` and
`.cache/redcase/browser-german-dialog.png` in the containing workspace. No browser
test records needed to be added for this follow-up; temporary integration records
were rolled back.
