# Architecture

## Overview

The app follows **MVVM** with a **repository pattern** and protocol-based dependency injection. Views are UIKit view controllers; view models expose `@Published` state via Combine; persistence and transport live in **Core**.

```
┌─────────────────────────────────────────────────────────┐
│  UIKit Views (Features/)                                │
│  ConversationsListViewController, ChatViewController    │
└───────────────────────────┬─────────────────────────────┘
                            │ bindings / callbacks
┌───────────────────────────▼─────────────────────────────┐
│  ViewModels (Combine @Published)                        │
│  InboxViewModel, ChatViewModel                          │
└───────────────────────────┬─────────────────────────────┘
                            │ ChatRepositoryProtocol
┌───────────────────────────▼─────────────────────────────┐
│  ChatRepository                                         │
│  optimistic writes · state transitions · retry dispatch │
└───────────────┬─────────────────────────┬───────────────┘
                │                         │
┌───────────────▼──────────────┐  ┌───────▼────────────────┐
│  LocalChatStore (JSON)       │  │  ChatTransport         │
│  AttachmentStorage (files)   │  │  MockChatTransport     │
└──────────────────────────────┘  └────────────────────────┘
```

## Layers

| Layer | Responsibility |
|-------|----------------|
| **App** | `AppDelegate`, `SceneDelegate`, `AppEnvironment` composition root |
| **Features** | Screen-specific view controllers, cells, input bars |
| **Core/Models** | Domain types, delivery state, connectivity |
| **Core/Repositories** | `ChatRepository` — coordinates store + transport |
| **Core/Persistence** | `LocalChatStore`, `AttachmentStorage` |
| **Core/Networking** | `ChatTransport`, `MockChatTransport`, `ConnectivityMonitor` |
| **Core/Mapping** | `MessageMapper` — record ↔ UI model |
| **Core/Services** | `RetryPolicy` |
| **Core/Configuration** | `MockChatConfiguration` — portfolio defaults |

## Data flow examples

**Send text:** `ChatViewController` → `ChatViewModel.sendText` → `ChatRepository.sendText` → persist as `.sending` → `MockChatTransport.send` → transition to `.sent` or `.failed` → `messagesDidChange` → view model reloads → table updates.

**Offline retry:** Settings toggle → `ConnectivityMonitor.setSimulatedOffline` → outbound send throws → `.failed` → user taps bubble or reconnects → `retrySend` / `flushFailedMessages` → `.retrying` → transport → `.sent`.

**Attachments:** Picker → file copied to `Documents/Attachments/` → `ChatMessageKind` with local URL → same outbound pipeline as text.

## Testability

- `ChatRepositoryProtocol` allows injecting fakes in view model tests.
- `AppEnvironment(store:transport:)` accepts custom store and transport for integration-style unit tests.
- `LocalChatStore(fileURL:)` writes to a temp file in tests — no shared sandbox state.
- State machine rules live in `MessageDeliveryState.canTransition(to:)` and are covered by unit tests.

## Extension points

| Protocol / type | Swap for |
|-----------------|----------|
| `ChatTransport` | WebSocket, REST, Firebase, or gRPC client |
| `ChatRepositoryProtocol` | Decorators (analytics, encryption) |
| `LocalChatStore` | Core Data, SQLite, or GRDB for scale |

See also:

- [Message lifecycle](MESSAGE_LIFECYCLE.md)
- [Offline & retry strategy](OFFLINE_RETRY.md)
