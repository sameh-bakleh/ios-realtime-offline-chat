# Security Policy

## Supported versions

| Branch | Supported |
|--------|-----------|
| `main` | Yes |
| `master` | Yes |

## Reporting a vulnerability

This is a **portfolio sample project** with no production deployment.

- **Do not** open public issues containing API keys, tokens, or personal data.
- For accidental secret exposure in the repository, contact the maintainer privately if possible, or open a minimal issue without pasting the secret.

## Security model

| Area | Approach |
|------|----------|
| Credentials | None required; `MockChatTransport` simulates network I/O |
| Data storage | App sandbox only (`Documents/chat_store.json`, `Documents/Attachments/`) |
| Dependencies | Apple system frameworks + XcodeGen; no third-party app SDKs |
| CI | No signing secrets; `CODE_SIGNING_ALLOWED=NO` for simulator builds |

## If you fork for production

- Implement `ChatTransport` with your backend; keep secrets in **CI secrets**, **local `.env`** (gitignored), or **Xcode `.xcconfig`** files listed in `.gitignore`.
- Never commit `GoogleService-Info.plist`, `.p12`, `.mobileprovision`, or `Secrets.xcconfig`.
- See [.env.example](.env.example) for optional variable documentation.

## Dependency surface

UIKit, Foundation, Combine, AVFoundation, PhotosUI, QuickLook, ImageIO — all system frameworks.
