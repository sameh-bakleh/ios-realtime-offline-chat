# Contributing

Thank you for your interest in this project. This is a **portfolio sample repository**; contributions that improve clarity, tests, or maintainability are welcome.

## Before you start

1. Read [README.md](README.md) and [SECURITY.md](SECURITY.md).
2. Do **not** commit API keys, Firebase configs, `.env` files with secrets, or company-specific code.
3. Keep changes focused — prefer small, reviewable pull requests.

## Documentation

- [Architecture](Docs/ARCHITECTURE.md)
- [Message lifecycle](Docs/MESSAGE_LIFECYCLE.md)
- [Offline & retry strategy](Docs/OFFLINE_RETRY.md)

## Development setup

```bash
brew install xcodegen
xcodegen generate
open RealtimeOfflineChat.xcodeproj
```

**Requirements:** Xcode 15+, iOS 16+ simulator.

## Running tests locally

```bash
xcodegen generate
xcodebuild test \
  -project RealtimeOfflineChat.xcodeproj \
  -scheme RealtimeOfflineChat \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

## Pull request guidelines

- Describe **what** changed and **why**.
- Note any README or architecture impact.
- Ensure `xcodebuild test` passes locally when touching Swift code.
- Add or update unit tests for behaviour changes (especially `ChatRepository`, state transitions, mappers).
- Avoid unrelated formatting or drive-by refactors.

## Code style

- Match existing patterns: UIKit programmatic layout, MVVM + Combine, repository injection via `AppEnvironment`.
- Prefer protocol-oriented abstractions over concrete backend coupling.
- Keep views thin; business logic belongs in ViewModels and `ChatRepository`.

## Reporting issues

Use the GitHub issue templates:

- **Bug report** — reproducible steps, expected vs actual behaviour, simulator/device.
- **Feature request** — problem statement and proposed scope (no obligation to implement).

## Security

Report sensitive findings privately if possible. Do not open public issues containing credentials or personal data.

See [SECURITY.md](SECURITY.md).
