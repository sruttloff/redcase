# Redcase for Redmine 6.1

Redcase adds test case management and execution to Redmine. Test cases remain standard Redmine issues and can be organized into test suites, executed for different versions and environments, and analyzed in reports.

This fork is maintained for Redmine 6.1 by **[SaaS-Secure.com, S. Ruttloff](https://www.saas-secure.com/)**. It is based on [Redcase by Bugzinga](https://github.com/bugzinga/redcase) and the [Redmine 6.0 adaptation by Uforia Infotech](https://github.com/Uforia-Infotech/redcase).

**Version: 1.1.0.** Tested with Redmine **6.1.2-stable**, Rails **7.2.3**, Ruby **3.3.7**, and MySQL **8.4.11**. Validation covers the workflows described in the [validation report](doc/REDMINE_6_1_VALIDATION.md); compatibility with other Redmine versions and database adapters has not been confirmed. See the [changelog](CHANGELOG.md) for release notes.

## Features

- Manage test cases as Redmine issues with descriptions and attachments.
- Organize test cases into nested test suites.
- Assign test cases to execution suites using drag and drop.
- Store results and comments for each version and environment.
- Review previous test executions in the execution history.
- Create a linked bug issue from a failed test.
- Analyze results in tables and charts.
- Export reports as CSV and test case specifications as RTF.

## Requirements

- Redmine 6.1 and the Ruby/Rails versions supported by that Redmine release.
- The gems listed in the plugin's `Gemfile`, particularly `acts_as_tree`.
- A backup before installation or upgrade.

## Installation

Check out the desired published revision of this fork in Redmine's plugin directory. The directory must be named exactly `redcase`:

```sh
cd /path/to/redmine/plugins
git clone --branch v1.1.0 https://github.com/sruttloff/redcase.git redcase
cd /path/to/redmine
bundle install
bundle exec rake redmine:plugins:migrate NAME=redcase RAILS_ENV=production
```

If your installation uses precompiled assets, rebuild them next:

```sh
bundle exec rake assets:precompile RAILS_ENV=production
```

Then restart the Redmine application server. The restart command depends on your deployment, such as Puma under systemd, Passenger, or Docker.

For an upgrade, first back up the database and plugin directory, fetch the desired revision, and repeat the steps for gems, migrations, assets, and restarting the application.

## Setup

1. Under **Administration → Trackers**, create or enable the **`Test case`** tracker and enable it in the project. The **`Bug`** tracker must also be enabled in the project to create bug issues.
2. Create or enable the **`In Progress`** and **`Obsolete`** issue statuses and allow the appropriate transitions in the Redmine workflow.
3. Under **Administration → Roles and permissions**, grant the required Redcase permissions:

   | Permission | Purpose |
   | --- | --- |
   | View test cases (`view_test_cases`) | Read test cases and reports |
   | Manage test cases (`edit_test_cases`) | Edit test suites, assignments, and environments |
   | Execute test cases (`execute_test_cases`) | Save test results and comments |

4. Grant the standard Redmine issue permissions as needed. In particular, **Add issues** is required to create test cases and bug issues.
5. Create at least one **version** in the project. Users with the appropriate permissions can access management without a version, but test execution requires one.

The names `Test case`, `Bug`, `In Progress`, and `Obsolete` are currently referenced directly in the code. They must retain these exact names regardless of the interface language. Renaming these trackers or statuses is not yet supported.

## Usage

1. Open **Test cases → Management** in the project and create test suites and environments.
2. Create an issue with the `Test case` tracker using the standard Redmine form. It initially appears under **Unsorted**.
3. Set the test case status to `In Progress` and use drag and drop in Management to assign it to the desired execution suite.
4. Under **Execution**, select an execution suite, version, and environment, open a test case, and save its result and comment.
5. Under **Report**, select the same version and environment. The table shows the latest result for each test case. Filters include individual results, **All results**, and **Not passed**.
6. **Export report (CSV)** downloads the results table as a UTF-8 CSV file with a BOM, suitable for spreadsheet applications. **Export test case specification (RTF)** downloads the test case descriptions.

### Localization

English and German interface text is provided for menus, dialogs, execution history, charts, and exports. Labels follow the language of the current Redmine session. The German interface uses consistent terminology for test suites, execution suites, environments, test executions, and results.

Internal result values (`Passed`, `Failed`, `Blocked`, `Not Available`, `Not Executed`) remain unchanged. The system folders `Root`, `.Unsorted`, and `.Obsolete` also retain their stored names and identifiers; the test case view translates their display labels. User-defined project, version, suite, and environment names are not translated.

Translations are scoped under `redcase` and do not override general Redmine labels. New strings fall back to English when a translation is unavailable in another language. Existing Polish and Russian labels are preserved.

## Changes for Redmine 6.1

- Removed obsolete `unloadable` calls and adapted model patches to Rails/Zeitwerk reloads.
- Protected hook registration against missing or duplicate listeners.
- Corrected JavaScript filenames for Linux and reused Redmine's existing jQuery.
- Enforced project boundaries, issue visibility, and separate view, management, and execution permissions.
- Fixed nested execution suites, chart counts, and copying between projects.
- Escaped dynamic text and completed German translations.
- Validated CSV/RTF exports and projects without a version.

## Validation and development

These checks require a development or test installation with plugin migrations applied and the trackers and statuses listed above:

```sh
bundle exec rake zeitwerk:check
bundle exec rails runner plugins/redcase/test/compatibility_smoke.rb
bundle exec rails runner plugins/redcase/test/reload_smoke.rb
```

The language-independent filter logic and JavaScript translation helper can also be checked with Node.js, without npm dependencies:

```sh
node plugins/redcase/test/localization_smoke.js
```

The compatibility test uses actual Rails requests and rolls back its temporary records. The reload test checks Redcase in isolation because other installed plugins may have their own reload issues. Browser checks and known limitations are documented in the [validation report](doc/REDMINE_6_1_VALIDATION.md).

## More plugins from SaaS-Secure.com

- **[Redmine UX Toolkit](https://www.saas-secure.com/online-services/redmine-ux-toolkit.html)** – Modern interface, dashboards, checklists, templates, reminders, and administration tools.
- **[SCM Creator for Redmine](https://www.saas-secure.com/online-services/redmine-scm.html)** – Repository management for Git, Subversion, Mercurial, Bazaar, and GitHub.

These plugins are optional additions and are not required by Redcase. For hosting and other services, visit **[www.saas-secure.com](https://www.saas-secure.com/)**.

## Support and credits

Report issues with this fork through **[GitHub Issues](https://github.com/sruttloff/redcase/issues)**. Please include your Redmine, Ruby, and Rails versions, along with steps to reproduce the problem.

- Original plugin: [Bugzinga Team](https://github.com/bugzinga/redcase).
- Redmine 6.0 adaptation: [Uforia Infotech](https://github.com/Uforia-Infotech/redcase), [Usman Shaukat](https://github.com/usmanpakistan).
- Redmine 6.1 adaptation and maintenance of this fork: [SaaS-Secure.com, S. Ruttloff](https://www.saas-secure.com/).

## License

Redcase is licensed under the **Apache License 2.0**. The original Bugzinga Team copyright notice is preserved; see [LICENSE](LICENSE).
