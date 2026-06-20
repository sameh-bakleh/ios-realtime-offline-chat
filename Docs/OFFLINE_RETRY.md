# Offline & retry strategy

The portfolio app simulates offline behaviour without a real network stack. The same patterns apply when swapping in a production `ChatTransport`.

## Principles

1. **Write locally first** — every outbound message is persisted before transport is attempted.
2. **Fail visibly** — transport errors surface as `.failed` with inline retry affordances.
3. **Retry with intent** — manual retries are immediate; automatic retries use exponential backoff.
4. **Reconnect flush** — when connectivity returns, failed messages are retried automatically (within limits).

## Offline detection

`ConnectivityMonitor` bridges the mock transport's `isSimulatedOffline` flag to `ConnectivityState`:

- **Settings → Simulate offline mode** toggles `transport.isSimulatedOffline`.
- Inbox and chat screens show an offline banner when `connectivity == .offline`.
- `ChatRepository` subscribes to `connectivityPublisher` and calls `flushFailedMessages()` when state becomes `.online`.

Production note: replace or extend `ConnectivityMonitor` with `NWPathMonitor` while keeping the same `ConnectivityState` publisher contract.

## Transport errors

`MockChatTransport.send` throws:

| Error | When |
|-------|------|
| `ChatTransportError.offline` | `isSimulatedOffline == true` |
| `ChatTransportError.simulatedFailure` | random failure based on `simulatedFailureRate` |

Default portfolio values live in `MockChatConfiguration` (0.45s latency, 12% failure rate). Tests set `simulatedFailureRate = 0` for determinism.

## Retry paths

### Manual retry

- Tap the delivery status icon on a failed outbound bubble.
- Context menu → **Retry send**.
- Calls `ChatRepository.retrySend(..., isManual: true)` — **no backoff delay**.

### Automatic retry on reconnect

When connectivity flips to online, `flushFailedMessages()` iterates all conversations and retries messages where:

- `author == .me`
- `deliveryState == .failed`
- `sendAttemptCount < RetryPolicy.maxAutomaticAttempts` (5)

Each retry increments `sendAttemptCount` and transitions to `.retrying`.

### Exponential backoff

For automatic retries (`isManualRetry == false`) with `sendAttemptCount > 0`:

```
delay = min(2^(attempt - 1), 30) seconds
```

| Attempt | Delay |
|---------|-------|
| 1 | 1s |
| 2 | 2s |
| 3 | 4s |
| 4 | 8s |
| 5+ | capped at 30s |

Implemented in `RetryPolicy.delaySeconds(forAttempt:)`.

## In-flight deduplication

`ChatRepository` tracks `inFlight: Set<UUID>` so duplicate retry dispatches for the same message ID are ignored while a send task is running.

## User-facing affordances

| Surface | Behaviour |
|---------|-----------|
| Failed bubble status icon | Tap to retry |
| Context menu | Retry send, copy, share, delete |
| Offline banner | Informational; does not block composing |
| Settings toggle | Demo offline mode for reviewers |

## Testing

| Test | File |
|------|------|
| Backoff math | `RetryPolicyTests` |
| Offline → failed | `ChatRepositoryTests.testOfflineSendMarksFailed` |
| Manual retry → sent | `ChatRepositoryTests.testManualRetryAfterFailureEventuallySends` |
| Auto flush on reconnect | `ChatRepositoryTests.testFlushFailedMessagesOnReconnect` |

## Production checklist

When implementing a real `ChatTransport`:

- Map HTTP 5xx / WebSocket disconnect to `.failed`, not silent drops.
- Persist `sendAttemptCount` (already in `ChatMessageRecord`).
- Consider server-side idempotency keys using `message.id`.
- Cap automatic retries and surface a "couldn't send" action after max attempts.
