# Flutter Scaffold CLI Roadmap

## Phase 1: Core CLI & Developer Experience

Focus on making the tool robust, configurable, and easy to use.

## Critical Bug Fixes (Next)

- [x] **Fix `init` command crash:**
  - [x] Await `_featureService.addFeature` call in `InitCommand` (missing `await` causes unhandled exception).
  - [x] Handle existing 'home' feature gracefully (skip if exists, don't crash).

- [/] **CLI Infrastructure**
  - [x] **Safety & Recovery:**
    - [x] **Automated Backups:** Backup modified files to `.flutter_scaffold/backups/` before any change.
    - [x] **Sandboxed Dry-Run (Verification):**
      - [x] Copy project files to a system temp directory (platform-independent).
      - [x] Execute the command in the sandbox to verify success.
      - [x] If successful, apply changes to actual project; otherwise, abort and report errors.
      - [x] Clean up temp artifacts automatically.
    - [x] **Post-Scaffold Verification:** Detect issues after generation; prompt user to "Continue" or "Revert".
    - [x] **History Tracking:** Maintain `.flutter_scaffold/history.json` to track changes for easy backtracking.
  - [x] **Git Integration:**
    - [x] Auto-commit changes using the project's standard format (refer to `commit-msg` hook).
    - [x] Support Conventional Commits with Emojis (e.g., `🐛 fix(scaffold): message`).
  - [x] **Standardize Command Verbs:**
    - [x] Rename `scaffold` command to `init` for initializing existing projects.
    - [x] Ensure usage consistency (e.g., `flutter_scaffold add <feature|component>`).
  - [x] Implement `upgrade` command for self-update mechanism.
  - [x] Implement `interactive` mode (TUI) for easier option selection.
  - [x] Add `verbose` flag (`--verbose`) for detailed debugging logs.
- [x] **Distribution & Usage**
  - [x] **Local Distribution (Pre-Publish Strategy):**
    - [x] **Bundled Resources:** Copy both `flutter_scaffold` executable and built VSCode extension (`.vsix`) to generated projects.
    - [x] **Easy Installation:** Allow users to install the extension manually from the local `.vsix` file until published.
    - [x] **Unified Upgrade:** Ensure `upgrade` command updates both the local executable and the `.vsix` file.
  - [x] **Smart Execution Wrapper:**
    - [x] Check local executable first (priority).
    - [x] Fallback to global command if local missing.
    - [x] Prompt to install if neither available.
  - [x] **Advanced Upgrade Mechanism:**
    - [x] Upgrade by fetching from git, building, and replacing artifacts.
    - [x] Support upgrade channels: `stable`, `beta`, `alpha`.
  - [x] **VSCode Integration in Generated Project:**
    - [x] Add `.vscode/extensions.json` recommending `flutter_scaffold` extension.
    - [x] Ensure extension works with local executable priority.
- [x] **IDE Integration (VSCode Extension)**
  - [x] Update TextMate grammar to support new template keywords (e.g., `{{if}}`, variables).
  - [x] Implement Language Server Protocol (LSP) or CompletionItemProvider for Intellisense.
  - [x] Ensure syntax highlighting identifies dynamic parts of templates.
  - [x] **Fix Extension Validation:**
    - [x] Add initial placeholders to known list: `FEATURE_NAME`, `PASCAL_NAME`, `MODEL_NAME`, `PASCAL_MODEL_NAME`, `FIELDS`, `FIELD_NAMES`.
    - [x] Add remaining placeholders: `PASCAL_FEATURE_NAME`, `screenName`, `PASCAL_SCREEN_NAME`, `FIELDS_WITH_OPTIONAL`, `COPY_FIELDS`, `JSON_FIELDS`, `FROM_JSON_FIELDS`, `HAS_FIELDS`.
    - [x] Rebuild extension (`npm run compile && npm run package`).
    - [x] Extension version bumped to `0.2.0`.
- [x] **Project Configuration & Defaults**
  - [x] **Optimal Defaults Strategy:**
    - [x] Ship with production-ready defaults (Riverpod, GoRouter, Freezed, Linting) that work out-of-the-box.
    - [x] Zero-config start: `flutter_scaffold create my_app` should just work.
  - [x] **Full Customization Options:**
    - [x] **CLI Flags:** Override any default (e.g., `--state-management bloc`, `--no-routes`, `--no-lint`).
    - [x] **Config File (`flutter_scaffold.yaml`):** Persist overrides project-wide or globally.
  - [x] Enhance `flutter_scaffold.yaml`:
    - [x] Support custom template paths.
    - [x] Define default "stack" preferences.

## Phase 2: Advanced Scaffolding & Architecture

Focus on generating "Complete" Clean Architecture support.

- [x] **Data Layer Generation** (High Priority)
  - [x] Generate `repository_impl` (Repository Implementation).
  - [x] Generate `datasource` (Remote & Local).
  - [x] Generate `mapper` classes (Entity <-> DTO).
- [x] **Component Generation**
  - [x] `add usecase` command.
  - [x] `add repository` command (Interface & Impl).
  - [x] `add model` command (with json_serializable).
- [x] **State Management Options**
  - [x] Support Bloc/Cubit generation (in addition to Riverpod).
- [x] **Scalability & Maintenance**
  - [x] Verify conditional rendering logic for all new components.
  - [x] Ensure `build_runner` and linters auto-run after generation.
  - [x] Fix repository template entity references (E2E failure).
  - [x] Standardize template variable naming across all commands.
  - [x] Add conditional entity handling (`HAS_ENTITY` flag) to templates.
  - [x] Update E2E tests to verify template generation.

## Phase 3: Production Readiness

Focus on "Go Live" requirements.

- [ ] **Testing & Quality**
  - [ ] **Test Refactoring (DRY):**
    - [ ] Create shared test utilities (temp dir creation, project scaffolding).
    - [ ] Standardize fixtures for unit and integration tests.
    - [ ] Refactor existing tests to use common setup/teardown logic.
  - [ ] Generate Unit Test stubs (using `mockito`).
  - [ ] Generate Widget Test boilerplate.
  - [x] **Comprehensive E2E Testing:**
    - [x] Update `scripts/e2e_test.dart` to test ALL commands (`init`, `add`, `remove`, `config`, `upgrade`).
    - [x] Test flag combinations (e.g., `--no-git`, `--no-backup`, `--force`, `--dry-run`).
    - [x] **Existing Project Verification:** Test running `init` on a pre-existing Flutter project (idempotency & integration).
    - [x] **Selective Execution:** Support running specific test steps via `--steps` flag.
  - [ ] Generate Integration Test boilerplate.
  - [ ] Setup `l10n` (Localization) infrastructure.
  - [ ] Implement Global Error Handling (Catcher/Boundary).
- [ ] **DevOps**
  - [ ] Generate CI/CD workflows (GitHub Actions, GitLab CI).
  - [ ] Generate Flavor setup (Dev, Staging, Prod).
  - [ ] Asset Management (type-safe `Assets` class generation).

## Completed

- [x] Implement `--screen` flag for feature generation.
- [x] Add unit tests for safety services (BackupService, HistoryService, SandboxService).
- [x] Implement CLI Infrastructure (upgrade, interactive, verbose).
- [x] **Phase 2 Complete:** Data layer templates, component commands, Bloc/Cubit templates.
