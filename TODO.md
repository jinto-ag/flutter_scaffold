# Flutter Scaffold CLI Roadmap

## Phase 1: Core CLI & Developer Experience

Focus on making the tool robust, configurable, and easy to use.

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
- [ ] **IDE Integration (VSCode Extension)**
  - [ ] Update TextMate grammar to support new template keywords (e.g., `{{if}}`, variables).
  - [ ] Implement Language Server Protocol (LSP) or CompletionItemProvider for Intellisense.
  - [ ] Ensure syntax highlighting identifies dynamic parts of templates.
- [ ] **Project Configuration & Defaults**
  - [ ] **Optimal Defaults Strategy:**
    - [ ] Ship with production-ready defaults (Riverpod, GoRouter, Freezed, Linting) that work out-of-the-box.
    - [ ] Zero-config start: `flutter_scaffold create my_app` should just work.
  - [ ] **Full Customization Options:**
    - [ ] **CLI Flags:** Override any default (e.g., `--state-management bloc`, `--no-routes`, `--no-lint`).
    - [ ] **Config File (`flutter_scaffold.yaml`):** Persist overrides project-wide or globally.
  - [ ] Enhance `flutter_scaffold.yaml`:
    - [ ] Support custom template paths.
    - [ ] Define default "stack" preferences.

## Phase 2: Advanced Scaffolding & Architecture

Focus on generating "Complete" Clean Architecture support.

- [ ] **Data Layer Generation** (High Priority)
  - [ ] Generate `repository_impl` (Repository Implementation).
  - [ ] Generate `datasource` (Remote & Local).
  - [ ] Generate `mapper` classes (Entity <-> DTO).
- [ ] **Component Generation**
  - [ ] `add usecase` command.
  - [ ] `add repository` command (Interface & Impl).
  - [ ] `add model` command (with json_serializable).
- [ ] **State Management Options**
  - [ ] Support Bloc/Cubit generation (in addition to Riverpod).
- [ ] **Scalability & Maintenance**
  - [ ] Verify conditional rendering logic for all new components.
  - [ ] Ensure `build_runner` and linters auto-run after generation.

## Phase 3: Production Readiness

Focus on "Go Live" requirements.

- [ ] **Testing & Quality**
  - [ ] Generate Unit Test stubs (using `mockito`).
  - [ ] Generate Widget Test boilerplate.
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
