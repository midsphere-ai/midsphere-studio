# Frontend Migration Guide: AWorld/Temporal → Orbiter

This guide documents all backend API changes from the AWorld/Temporal architecture to Orbiter, so the Flutter frontend team can update the mobile and web clients.

---

## 1. API Architecture Change (Two-Phase API)

### Before (AWorld/Temporal) — Three Endpoints

1. **POST** `/completions/start` → Returns `{conversation_id, status: "preparing"}` immediately
2. **GET** `/completions/stream/{conversation_id}/` → SSE endpoint that **polls** for the task to start, then relays events from Redis
3. *(Optional)* **GET** `/completions/{conversation_id}/status` → Poll for task status

The old flow required the SSE endpoint to **wait** for the background preparation to complete (sandbox creation, resource validation, MCP config) before events could stream. During this startup phase, the SSE endpoint sent heartbeat comments every 1s while polling the database for the task to appear.

### After (Orbiter) — Two Endpoints

1. **POST** `/completions/start` → Does **all** preparation synchronously, returns `{task_id, conversation_id}`
2. **GET** `/completions/{task_id}/events` → SSE endpoint streams events by `task_id` immediately (no startup polling)

The new flow does all validation, sandbox creation, and dispatch **inside the POST request**. If anything fails, you get an HTTP error immediately (400/403/404/429). If the POST succeeds, the returned `task_id` is guaranteed to be ready for streaming.

### Key Differences

| Aspect                  | Before                        | After                           |
| ----------------------- | ----------------------------- | ------------------------------- |
| POST returns            | `{conversation_id, status}` | `{task_id, conversation_id}`  |
| Failures reported via   | Deferred SSE errors           | Immediate HTTP status codes     |
| SSE endpoint key        | `conversation_id`           | `task_id`                     |
| SSE startup phase       | Polls DB up to 120s for task  | None — task already dispatched |
| Status polling endpoint | Existed (optional)            | Removed                         |

### Breaking Changes

- **`task_id` is now returned from POST** — previously it was an internal detail not exposed to the frontend
- **SSE streaming uses `task_id`** (not `conversation_id`) — the URL pattern changed
- **POST response schema changed** — no `status` or `message` fields, replaced with `task_id`
- **No startup polling phase** — the SSE endpoint streams events immediately upon connection
- **Error reporting moved to POST** — the SSE endpoint no longer sends preparation errors

---

## 2. Execute Agent Endpoint (Updated)

**URL**: `POST /chat/completions/start` (unchanged)

### Request (Unchanged)

```
Content-Type: multipart/form-data
Authorization: Bearer <token>

conversation_id: string (required)
message: string (required)
files: list[string] (file IDs)
addons: list[string] (addon IDs)
mcp: list[string] (MCP config IDs)
model: string (optional, model ID)
customise: dict (optional, JSON string)
incognito: bool (default: false)
files: UploadedFile[] (multipart file uploads)
```

### Response

```json
// Before (AWorld/Temporal)
{
  "conversation_id": "conv456",
  "status": "preparing",
  "message": "Agent execution starting"
}

// After (Orbiter)
{
  "task_id": "abc123",
  "conversation_id": "conv456"
}
```

**Changes:**

- **`task_id` added** — use this for the streaming endpoint and cancellation lookups
- **`status` removed** — the POST is synchronous; if it returns 200, the task is dispatched
- **`message` removed** — no need for a status message on synchronous success

### Error Responses (Updated)

| Status | When                                    | Response                                                       |
| ------ | --------------------------------------- | -------------------------------------------------------------- |
| 400    | Validation failure (bad input)          | `{"error": "...", "status": "error"}`                        |
| 403    | Authorization failure (limits exceeded) | `{"error": "...", "status": "limit_exceeded"}`               |
| 403    | Not authorized for conversation         | `{"error": "...", "status": "unauthorized"}`                 |
| 404    | Conversation not found                  | `{"error": "...", "status": "not_found"}`                    |
| 409    | Conversation already active             | `{"error": "...", "status": "conflict"}`                     |
| 429    | No workers available                    | `{"error": "...", "status": "no_workers", "retry_after": 5}` |

**Changes:**

- **429 replaces 503** for no workers — semantically correct for rate/capacity limiting
- **409 Conflict** added for concurrent task attempts (previously returned a generic error)
- **All errors are JSON** `{error, status}` — no more deferred SSE errors for preparation failures
- **403 for limit exceeded** — subscription limits, execution quotas are authorization-level failures

---

## 3. SSE Streaming Endpoint (Rewritten)

### Before

**URL**: `GET /chat/completions/stream/{conversation_id}/`

- Keyed by `conversation_id` — the endpoint looked up the task internally
- Had a startup polling phase (up to 120s) waiting for the background preparation to complete
- Used Redis pub/sub relay from the worker

### After

**URL**: `GET /chat/completions/{task_id}/events`

- Keyed by `task_id` — obtained from the POST response
- No startup polling — the task is already dispatched when the POST returns
- Direct EventSubscriber connection to Orbiter's Redis event streams

### SSE Protocol

- Content-Type: `text/event-stream`
- `retry: 1000` sent at stream start (1-second reconnection interval)
- Heartbeat: `: heartbeat\n\n` comments every 15 seconds during idle periods
- 30-minute max stream duration (unchanged)

### Reconnection (Last-Event-ID)

When the connection drops:

1. The browser/client automatically reconnects (within `retry` interval)
2. Include `Last-Event-ID` header with the last received event ID
3. The server replays missed events from Redis Stream, then switches to live pub/sub

**Event IDs are sequential integers** (`1`, `2`, `3`, ...). Terminal events use prefixed IDs (`complete-N`, `error-N`).

### SSE Event Types

| SSE Event Name | Purpose          | Notes                                                      |
| -------------- | ---------------- | ---------------------------------------------------------- |
| `message`    | Agent event data | Contains the JSON payload (TextEvent, ToolCallEvent, etc.) |
| `complete`   | Task finished    | Terminal event — close the stream                         |
| `error`      | Internal error   | Stream error — close the stream                           |

### Terminal Events

When the task finishes (completed, error, cancelled), the server sends:

```
id: complete-42
event: complete
data: {"type": "complete", "status": "completed", "reason": "Task completed successfully"}
```

Possible `status` values in the complete event: `"completed"`, `"error"`, `"cancelled"`, `"timeout"`

After receiving `event: complete`, close the SSE connection.

---

## 4. SSE Event Payloads

### Event: `message` (SSE event name)

All agent events are wrapped as `event: message` SSE events. The `data` field contains a JSON object with a `type` discriminator.

#### TextEvent → `message_output`

```json
// Before (AWorld)
{
  "type": "message_output",
  "data": {
    "response": "Here is the answer...",
    "tool_calls": [{"name": "search", "arguments": "..."}],
    "reasoning": "Extended thinking...",
    "has_reasoning": true
  }
}

// After (Orbiter)
{
  "type": "message_output",
  "data": {
    "response": "Here is the answer...",
    "agent_name": "Sukuna",
    "finished": false,
    "tool_calls": null,
    "reasoning": null,
    "has_reasoning": false
  }
}
```

**Changes:**

- `tool_calls` is always `null` — tool calls are now separate `tool_call` events
- `reasoning` is always `null` — reasoning is now a separate `reasoning` event
- `has_reasoning` is always `false` — check for `reasoning` event type instead
- Added `agent_name` field (string, identifies which agent in a swarm produced the text)
- Added `finished` field (always `false` in streamed events)

#### ToolCallEvent → `tool_call` (New)

```json
{
  "type": "tool_call",
  "data": {
    "tool_name": "mcp__e2b__execute_code",
    "tool_call_id": "call_abc123",
    "agent_name": "Sukuna"
  }
}
```

**This is a new event type.** Previously, tool calls were embedded in `message_output.tool_calls`. Now they're separate events that arrive *before* the corresponding `tool_result_output`.

#### ToolResultEvent → `tool_result_output`

```json
// Before (AWorld)
{
  "type": "tool_result_output",
  "data": {
    "tool_name": "mcp__e2b__execute_code",
    "data": {"status": "success", "output": "..."},
    "origin_tool_call": {
      "function": {
        "name": "execute_code",
        "arguments": "{\"code\": \"print('hello')\"}"
      }
    }
  }
}

// After (Orbiter)
{
  "type": "tool_result_output",
  "data": {
    "tool_name": "mcp__e2b__execute_code",
    "tool_call_id": "call_abc123",
    "arguments": {"code": "print('hello')"},
    "data": {"status": "success", "output": "..."},
    "error": null,
    "success": true,
    "duration_ms": 1250.5,
    "agent_name": "Sukuna"
  }
}
```

**Changes:**

- `origin_tool_call` removed — replaced by `tool_call_id` and `arguments`
- `arguments` is a parsed `dict`, not a JSON string (no more `json.loads()` needed)
- Added `tool_call_id` (string) — matches the `tool_call_id` from the preceding `tool_call` event
- Added `error` (string | null) — error message if the tool failed
- Added `success` (boolean) — whether the tool execution succeeded
- Added `duration_ms` (float) — execution time in milliseconds
- Added `agent_name` (string)

#### StepEvent → `step_output`

```json
// Before (AWorld)
{
  "type": "step_output",
  "data": {
    "step_number": 3,
    "agent_name": "Sukuna"
  }
}

// After (Orbiter)
{
  "type": "step_output",
  "data": {
    "step_number": 3,
    "agent_name": "Sukuna",
    "status": "completed",
    "started_at": "2026-02-19T10:30:00Z",
    "completed_at": "2026-02-19T10:30:05Z",
    "usage": {
      "prompt_tokens": 1500,
      "completion_tokens": 300,
      "total_tokens": 1800
    }
  }
}
```

**Changes:**

- Added `status` (string) — `"started"`, `"completed"`, `"failed"`
- Added `started_at` and `completed_at` (ISO 8601 timestamps | null)
- Added `usage` (object | null) — token usage for this step

#### StatusEvent → `status` (New)

```json
{
  "type": "status",
  "data": {
    "status": "completed",
    "agent_name": "Sukuna",
    "message": "Task completed successfully"
  }
}
```

**This is a new event type.** Indicates the overall task status. Terminal statuses (`completed`, `error`, `cancelled`) are immediately followed by an `event: complete` SSE event.

Possible `status` values: `"running"`, `"completed"`, `"error"`, `"cancelled"`

#### ErrorEvent → `error` (New)

```json
{
  "type": "error",
  "data": {
    "error": "Connection to MCP server timed out",
    "error_type": "ConnectionError",
    "agent_name": "Sukuna",
    "step_number": 5,
    "recoverable": true
  }
}
```

**This is a new event type.** Previously, errors were communicated via the `complete` SSE event or database message. Now they're inline events.

- `recoverable: true` means the agent may continue after this error
- `recoverable: false` means the task is terminating

#### ReasoningEvent → `reasoning` (New)

```json
{
  "type": "reasoning",
  "data": {
    "text": "Let me think about this step by step...",
    "agent_name": "Sukuna"
  }
}
```

**This is a new event type.** Previously, reasoning was embedded in `message_output.reasoning`. Now it's a separate event that arrives before the corresponding `message_output`.

#### UsageEvent → `usage` (New)

```json
{
  "type": "usage",
  "data": {
    "usage": {
      "prompt_tokens": 1500,
      "completion_tokens": 300,
      "total_tokens": 1800
    },
    "agent_name": "Sukuna",
    "step_number": 3,
    "model": "vertex:zai-org/glm-5-maas"
  }
}
```

**This is a new event type.** Reports token usage per step. Can be used for real-time token tracking in the UI.

### Event: `complete` (SSE event name)

```json
// Before (AWorld) - status came from conversation state polling
{
  "type": "complete",
  "status": "done"
}

// After (Orbiter) - status comes from StatusEvent via Redis
{
  "type": "complete",
  "status": "completed",
  "reason": "Task completed successfully"
}
```

**Changes:**

- `status` values changed: `"done"` → `"completed"`, added `"cancelled"`, `"timeout"`, `"error"`
- Added `reason` field (string) — human-readable description

---

## 5. Message Pagination (New)

### Before

- Previous chat messages loaded via SSE replay (re-streaming past events)
- Or loaded from Django `Message` table via a separate sync endpoint

### After

- **New endpoint**: `GET /chat/completions/conversations/{conversation_id}/messages`
- Reads from Orbiter's `memory_items` table (same store that persists agent turns)
- Falls back to Django `Message` table for pre-migration conversations

### Request

```
GET /chat/completions/conversations/{conversation_id}/messages?page=1&page_size=50
Authorization: Bearer <token>
```

| Parameter     | Type | Default | Notes                    |
| ------------- | ---- | ------- | ------------------------ |
| `page`      | int  | 1       | Page number (1-indexed)  |
| `page_size` | int  | 50      | Items per page (max 200) |

### Response

```json
{
  "messages": [
    {
      "type": "user",
      "content": "What is the capital of France?",
      "tool_calls": null,
      "tool_name": null,
      "is_error": null,
      "created_at": "2026-02-19T10:30:00Z",
      "metadata": {"session_id": "conv456"}
    },
    {
      "type": "message_output",
      "content": "The capital of France is Paris.",
      "tool_calls": [{"id": "call_abc", "name": "search", "arguments": "..."}],
      "tool_name": null,
      "is_error": null,
      "created_at": "2026-02-19T10:30:05Z",
      "metadata": {"session_id": "conv456"}
    },
    {
      "type": "tool_result_output",
      "content": "{\"result\": \"Paris\"}",
      "tool_calls": null,
      "tool_name": "mcp__e2b__execute_code",
      "is_error": false,
      "created_at": "2026-02-19T10:30:03Z",
      "metadata": {"session_id": "conv456"}
    }
  ],
  "total_count": 150,
  "page": 1,
  "page_size": 50
}
```

### Type Mapping (Memory Store → Response)

| Memory Type     | Response `type`      | Extra Fields                             |
| --------------- | ---------------------- | ---------------------------------------- |
| `HumanMemory` | `user`               | —                                       |
| `AIMemory`    | `message_output`     | `tool_calls` (list of tool call dicts) |
| `ToolMemory`  | `tool_result_output` | `tool_name`, `is_error`              |

### Error Responses

| Status | When                            | Response                                       |
| ------ | ------------------------------- | ---------------------------------------------- |
| 403    | Not authorized for conversation | `{"error": "...", "status": "unauthorized"}` |
| 404    | Conversation not found          | `{"error": "...", "status": "not_found"}`    |

---

## 6. Task Cancellation

**URL**: `POST /chat/completions/{conversation_id}/cancel` (unchanged)

### Response (Updated)

```json
// Before (AWorld/Temporal)
{
  "cancelled": true,
  "workflow_id": "temporal_wf_abc123"
}

// After (Orbiter)
{
  "cancelled": true,
  "message": "Cancellation requested"
}
```

**Changes:**

- `workflow_id` removed — replaced by internal `task_id`
- Added `message` field
- Cancellation is now via Redis pub/sub (`orbiter:cancel:{task_id}`) instead of Temporal workflow cancellation

---

## 7. Worker Capacity Check

The capacity check is called internally before task execution. If you display worker status in the UI:

```json
// Before (AWorld/Temporal)
{
  "has_capacity": true,
  "worker_count": 2
}

// After (Orbiter)
{
  "has_capacity": true,
  "reason": "ok",
  "message": "Workers available",
  "worker_count": 3,
  "alive_count": 2,
  "workers": [
    {
      "worker_id": "worker-1",
      "alive": true,
      "status": "healthy",
      "message": "Heartbeat within threshold",
      "tasks_processed": 150,
      "tasks_failed": 2,
      "hostname": "worker-pod-1"
    }
  ]
}
```

**Changes:**

- Per-worker health status with `healthy`, `degraded`, `unhealthy` states
- Added `alive_count`, `workers` list with detailed per-worker info
- Added `reason` field (`"ok"`, `"no_workers"`, `"health_check_error"`)

---

## 8. Human-in-the-Loop (HITL) Changes

### Before (AWorld)

- Agent used the `HUMAN` tool (from `aworld.tools.human.human`)
- Tool name exposed to frontend: `human_confirm`
- Ask message used prefix codes: `1|` (yes/no), `2|` (text input), `3|` (file upload)
- Response sent via RuntimeStateManager state update

### After (Orbiter)

- Agent uses `HumanInputTool` (from `orbiter.human`)
- Tool name exposed to frontend: `human_input`
- Ask message has structured fields: `prompt` and optional `choices` list
- Response sent via new API endpoint

### Ask Message Format

The ask message is delivered via SSE:

```json
{
  "type": "tool_result_output",
  "message": "Please confirm: should I deploy to production?",
  "metadata": {
    "tool_name": "human_input",
    "arguments": {
      "type": "ask",
      "text": "Please confirm: should I deploy to production?",
      "choices": ["Yes, deploy", "No, cancel"]
    },
    "hitl": true
  }
}
```

**Detection:** Check `metadata.hitl == true` and `metadata.tool_name == "human_input"` to identify HITL ask events.

### Response Endpoint

**URL**: `POST /chat/completions/{conversation_id}/respond`

```json
// Request
{
  "response": "Yes, deploy"
}

// Response
{
  "status": "ok",
  "message": "Response delivered"
}
```

---

## 9. Removed Endpoints and Features

### Removed Endpoints

| Endpoint                                       | Reason                                                              |
| ---------------------------------------------- | ------------------------------------------------------------------- |
| `GET /completions/stream/{conversation_id}/` | Replaced by `GET /completions/{task_id}/events` (US-007/008)      |
| `GET /completions/{conversation_id}/status`  | No longer needed — POST is synchronous, task status via SSE events |

### Removed Features

| Feature                                              | Status  | Notes                                                                                                       |
| ---------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------- |
| SSE startup polling phase                            | Removed | POST now does all prep synchronously — no waiting for task to appear                                       |
| Database-polling SSE                                 | Removed | Replaced by Redis pub/sub direct subscription                                                               |
| `seen_message_ids` eviction                        | Removed | No longer needed (events are not DB-polled)                                                                 |
| Per-step Redis cache                                 | Removed | Events stream directly via pub/sub                                                                          |
| `status` and `message` in POST response          | Removed | Replaced by `task_id` (POST is synchronous, success = dispatched)                                         |
| `workflow_id` in cancel response                   | Removed | Internal detail                                                                                             |
| `HUMAN` tool prefix codes (`1\|`, `2\|`, `3\|`) | Removed | Replaced by structured `choices` field                                                                    |
| `message_output.tool_calls` embedded array         | Removed | Now separate `tool_call` events                                                                           |
| `message_output.reasoning` embedded field          | Removed | Now separate `reasoning` events                                                                           |
| Agent output written to `Message` table            | Removed | Orbiter MemoryPersistence writes to `memory_items` table; `Message` table kept for historical data only |
| `AgentExecutor` class                              | Deleted | Business logic extracted to standalone services and worker `on_task_done`                                 |

### Data Source Change

Agent conversation data now lives in the Orbiter `memory_items` table, not the Django `Message` table:

| Concern                  | Before                                        | After                                                                 |
| ------------------------ | --------------------------------------------- | --------------------------------------------------------------------- |
| Agent output persistence | `Message` table (Django)                    | `memory_items` table (Orbiter MemoryPersistence)                    |
| Chat history loading     | `Message` table query                       | Memory store (with `Message` table fallback for pre-migration data) |
| Message pagination       | Sync endpoint on `Message` table            | New async endpoint on `memory_items` table (Section 5)              |
| Incognito cleanup        | `Message.objects.filter(task=...).delete()` | `PostgresMemoryStore.clear(scope)`                                  |

---

## 10. New Features

| Feature                          | Description                                                                           |
| -------------------------------- | ------------------------------------------------------------------------------------- |
| Two-phase API                    | Synchronous POST returns `{task_id, conversation_id}`; streaming GET by `task_id` |
| `task_id` in POST response     | Task ID returned immediately — no polling needed                                     |
| Memory-backed message pagination | `GET /conversations/{id}/messages` reads from Orbiter memory store                  |
| `tool_call` event type         | Separate event for tool invocations (before result)                                   |
| `reasoning` event type         | Separate event for extended thinking                                                  |
| `error` event type             | Inline error events with recoverability info                                          |
| `status` event type            | Task lifecycle status changes                                                         |
| `usage` event type             | Per-step token usage metrics                                                          |
| `agent_name` on all events     | Identifies which agent in a swarm produced the event                                  |
| HITL response endpoint           | `POST /completions/{conversation_id}/respond`                                       |
| Redis Stream replay              | Reconnection replays missed events from Redis Stream                                  |
| Worker health details            | Per-worker health status (`healthy`/`degraded`/`unhealthy`)                     |
| `step_output` timing           | `started_at`, `completed_at`, `usage` fields on step events                     |

---

## 11. Migration Checklist for Flutter Team

### Phase 1: POST Endpoint Update (Required First)

- [ ] Update POST response parsing: extract `task_id` from response (new field)
- [ ] Store `task_id` alongside `conversation_id` after POST succeeds
- [ ] Handle new error codes: 400 (validation), 403 (limits/auth), 404 (not found), 409 (conflict), 429 (no workers)
- [ ] Handle 429 response with `retry_after` field for backoff
- [ ] Remove any status polling logic (`GET /completions/{id}/status` is gone)

### Phase 2: SSE Endpoint Migration (Depends on Phase 1)

- [ ] Change SSE URL from `/completions/stream/{conversation_id}/` to `/completions/{task_id}/events`
- [ ] Pass `task_id` (from POST response) instead of `conversation_id` to the SSE endpoint
- [ ] Remove startup polling logic — no longer needed (no heartbeat-wait-for-task phase)
- [ ] Update `Last-Event-ID` handling: now sequential integers (`1`, `2`, `3`), not UUIDs
- [ ] Handle `complete` event `status` values: `completed`, `cancelled`, `timeout`, `error`
- [ ] Handle `complete` event `reason` field for user-facing messages

### Phase 3: Event Parsing Updates

- [ ] Parse new event types: `tool_call`, `status`, `error`, `reasoning`, `usage`
- [ ] Update `message_output` parsing: `tool_calls` and `reasoning` are always null (use separate events)
- [ ] Update `tool_result_output` parsing: `arguments` is now a dict (not JSON string), new fields `tool_call_id`, `error`, `success`, `duration_ms`
- [ ] Update `step_output` parsing: new fields `status`, `started_at`, `completed_at`, `usage`
- [ ] Read `agent_name` from all events (useful for multi-agent swarm UI)

### Phase 4: Message Pagination Migration

- [ ] Implement `GET /conversations/{conversation_id}/messages` for loading chat history
- [ ] Add pagination support: `page` and `page_size` query parameters
- [ ] Handle the response schema: `{messages, total_count, page, page_size}`
- [ ] Map message types: `user` (human), `message_output` (AI with optional `tool_calls`), `tool_result_output` (tool with `tool_name`, `is_error`)
- [ ] Remove any SSE replay logic for loading past messages (if previously used)

### Phase 5: HITL Updates

- [ ] Detect HITL ask: check `metadata.hitl == true` and `metadata.tool_name == "human_input"`
- [ ] Remove prefix code parsing (`1|`, `2|`, `3|`) — use `metadata.arguments.choices` instead
- [ ] Send HITL response to `POST /chat/completions/{conversation_id}/respond` with `{"response": "..."}` body

### Phase 6: Cleanup

- [ ] Remove references to old SSE endpoint (`/completions/stream/{conversation_id}/`)
- [ ] Remove status polling endpoint references (`/completions/{conversation_id}/status`)
- [ ] Remove code that handles the old POST response schema (`status: "preparing"`, no `task_id`)
- [ ] Update conversation history loading to use the new pagination endpoint (Section 5)
- [ ] Update message type filtering: add `tool_call`, `status`, `error`, `reasoning`, `usage` types
- [ ] Remove code that references `OutputModel`, `MessageOutputModel`, `ToolResultOutputModel`, `StepOutputModel`, `ToolCallOutputModel` — these tables no longer exist