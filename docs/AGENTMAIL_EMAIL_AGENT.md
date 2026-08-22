# AgentMail Email Agent

## Inbound path

```text
AgentMail message.received
→ n8n webhook with raw body
→ verify Svix signature and timestamp
→ require inbox_id + thread_id + message_id + event_id
→ deduplicate event
→ store thread and message
→ quarantine attachments
→ classify email
→ retrieve matching thread memory
→ draft or route response
→ approval inbox when customer-facing
```

AgentMail signs webhook events with `svix-id`, `svix-signature`, and `svix-timestamp`. Production must verify the signature against the exact raw request body before parsing or acting.

## Thread matching

`thread_id` identifies the conversation and is persisted on every message. `message_id` identifies the specific message. AgentMail's reply endpoint is:

```text
POST /v0/inboxes/:inbox_id/messages/:message_id/reply
```

The reply workflow therefore looks up the latest valid inbound `message_id` in the stored `thread_id`, sends the approved content, and requires the returned `thread_id` to match the expected thread.

## Safety

- webhook event IDs are idempotency keys for inbound processing;
- outbound requests have separate idempotency keys and content hashes;
- attachments are metadata-only until scanned;
- customer-facing replies require approval at launch;
- send success requires response content validation, not only HTTP success;
- sent, delivered, bounced, complained, and rejected events update message state;
- unknown, malformed, unsigned, duplicate, or mismatched events fail closed.

The n8n host must expose raw webhook bodies and allow the Node `crypto` built-in for signature verification, or verification must occur in a trusted gateway before n8n.
