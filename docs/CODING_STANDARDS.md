# Coding Standards

Follows [Effective Dart](https://dart.dev/effective-dart) and the strict ruleset in
`analysis_options.yaml` (strict-casts/inference/raw-types, `avoid_print`, `prefer_const_*`,
`require_trailing_commas`, `only_throw_errors`, `use_build_context_synchronously`, etc.).

## Rules

- **Single responsibility per file/class.** One public type per file where practical.
- **No generic names.** Avoid bare `Controller`/`Service`/`Manager`. Use
  `AuthController`, `DashboardController`, `SyncManager`, `ControlUnitScreen`, etc. Class names
  are unique across the codebase.
- **No duplication.** Reusable UI lives in `shared/design_system` and `shared/widgets`; reusable
  logic in `core`. No duplicate widgets, APIs, or business logic.
- **No hardcoded values in UI.** Colors → `AppColors`, text styles → `AppTextStyles`, spacing →
  `AppSpacing`, radius → `AppRadius`, icons → `AppIcons`, strings → `LocaleKeys`.
- **No `print`.** Use `AppLogger`.
- **Never return `null` for errors.** Use `Result<T>` and `Failure`.
- **No business logic in widgets / `setState`.** Use Riverpod.

## Naming conventions

| Kind | Convention | Example |
| --- | --- | --- |
| Files | `snake_case.dart` | `auth_repository_impl.dart` |
| Types | `PascalCase` | `DashboardSummary` |
| Members / vars | `lowerCamelCase` | `pendingSyncCount` |
| Constants | `lowerCamelCase` | `LocaleKeys.authLoginTitle` |
| Providers | `<name>Provider` | `authControllerProvider` |

## Commits & reviews

- Keep changes feature-scoped; respect layer boundaries (no `core → features` imports).
- `flutter analyze` must report **0 issues**; tests must pass; format with `dart format`.
- New user-facing strings require entries in both `en.json` and `hi.json` + a `LocaleKeys` constant.
