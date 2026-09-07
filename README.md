# Salesforce Headless 360 — MCP + Async Batch Processing POC

A proof-of-concept architecture demonstrating how to safely expose long-running, asynchronous Salesforce operations (Batch Apex, mass record updates) to an AI agent through the **Model Context Protocol (MCP)** — without blocking the agent's session, and without losing track of the result once the job completes.

## The Problem

MCP is a synchronous, request/response tool-calling protocol: an agent calls a tool, waits, and gets a result back in the same turn. Salesforce, at real data volume, is not synchronous — mass updates run as **Batch Apex** jobs that can take minutes to complete, well outside any single agent tool call.

This repo is a working answer to: *how does an AI agent kick off a long-running Salesforce job, walk away, and still get notified with accurate results once it's done?*

## Architecture

```
Agent (Claude) 
   │  calls MCP tool
   ▼
Salesforce Hosted MCP Server
   │  invokes External Service (ApexRest)
   ▼
MassUpdateAccountsRestApi (Apex REST)
   │  starts batch, returns job ID immediately — non-blocking
   ▼
MassUpdateAccountsBatch (Database.Batchable)
   │  runs async, updates records in chunks
   │  finish() publishes a Platform Event once complete
   ▼
Bulk\_Job\_Settled\_\_e (Platform Event)
   │  triggers BulkJobSettledTrigger (runs as Automated Process)
   ▼
NotifyRoutineQueueable (Queueable, allows callouts)
   │  POSTs job outcome via Named/External Credential
   ▼
Claude Code Routine (API-triggered)
   │  wakes up in a new session with the job outcome
   ▼
Slack (#salesforce-jobs)
   Posts a human-readable summary of the completed job
```

## Why It's Built This Way

* **Platform Events over a direct callout from `finish()`** — decouples "job is done" from "someone got notified," so other processes can subscribe to the same completion signal later without touching the batch class.
* **Permission Set assigned directly to the Automated Process User** — Platform Event triggers run as the **Automated Process** system entity by default, and this identity has no standard way to be granted a Permission Set through Setup UI (Salesforce blocks it there). This repo's fix: a narrow, single-purpose Permission Set — **`Callout Permission`** — granting *only* External Credential Principal Access, nothing else, assigned to the Automated Process User directly via Apex (`insert new PermissionSetAssignment(...)`). A broader/pre-existing permission set will likely fail here if it bundles anything requiring a license Automated Process doesn't hold; keep this one minimal.
* **External Credential over hardcoded secrets** — the bearer token for the outbound callout is never stored in Apex or Custom Metadata; it lives in a Salesforce-managed External Credential, injected at callout time.
* **Claude Code Routine (API trigger) as the wake-up mechanism** — since neither Claude.ai nor ChatGPT support pushing a message into an existing chat thread from an external event, this repo uses a Routine's dedicated API endpoint as the actual "resume" mechanism: each Platform Event fire starts a fresh, context-carrying session that completes the notification loop.

## Repo Structure

```
force-app/main/default/
├── classes/
│   ├── MassUpdateAccountsRestApi.cls      # Entry point — starts the batch, returns immediately
│   ├── MassUpdateAccountsBatch.cls        # Batchable — does the mass update, publishes completion event
│   └── NotifyRoutineQueueable.cls         # Queueable — makes the outbound callout to the Routine
├── triggers/
│   └── BulkJobSettledTrigger.trigger      # Subscribes to the Platform Event
├── objects/
│   └── Bulk\_Job\_Settled\_\_e/               # Platform Event definition and fields
└── externalServiceRegistrations/
    ├── MassUpdateAccountsRestApi.externalServiceRegistration-meta.xml
    └── MassUpdateAccountsRestApi.yaml     # OpenAPI spec — exposes the REST endpoint as an MCP tool
```

## Setup

This POC assumes:

* A Salesforce org with **Hosted MCP Servers** enabled (Setup → MCP Servers)
* A **Named Credential** + **External Credential** configured for outbound authentication to the Claude Code Routine endpoint
* A **Claude Code Routine** created with an API trigger, and a Slack connector attached for delivering the final summary
* A dedicated, minimal **Permission Set** named **`Callout Permission`**, granting only External Credential Principal Access (`Claude\_Routine\_Credential` / `AnthropicPrincipal`), assigned directly to the org's **Automated Process User** — no point-and-click path exists for this step, it must be done via Apex:

```apex
User autoProcUser = \[SELECT Id FROM User WHERE UserType = 'AutomatedProcess' LIMIT 1];
PermissionSet ps = \[SELECT Id FROM PermissionSet WHERE Name = 'Callout_Permission' LIMIT 1];
insert new PermissionSetAssignment(AssigneeId = autoProcUser.Id, PermissionSetId = ps.Id);
```

Deploy order:

1. `objects/Bulk\_Job\_Settled\_\_e` (Platform Event + fields)
2. `classes/` (Batch, REST endpoint, Queueable)
3. `triggers/BulkJobSettledTrigger`
4. Create the `Callout Permission` Permission Set and assign it to the Automated Process User (Execute Anonymous — see Setup section above)
5. `externalServiceRegistrations/` (registers the REST endpoint for MCP tool discovery)
6. Attach the resulting operation to your MCP Server definition in Setup

## Testing

Run a small batch first — not the full record volume:

```apex
Database.executeBatch(new MassUpdateAccountsBatch('Technology'), 200);
```

Check **Setup → Apex Jobs** for completion, then confirm the Platform Event → Queueable → Routine → Slack chain fired correctly before scaling up.

## Status

Working POC. Tested end-to-end against a Developer Edition org with a small dataset. Not yet load-tested at full enterprise volume (20,000+ records) or hardened for production (see: per-record failure detail from Bulk API's `failedResults` endpoint is not yet surfaced — only summary counts are).

