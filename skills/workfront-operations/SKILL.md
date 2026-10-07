---
name: workfront-operations
description: "Use when a user wants to find, summarize, create, update, or manage Adobe Workfront projects, tasks, issues, documents, approvals, assignments, users, programs, portfolios, or Planning records through the Workfront MCP connector."
---

# Adobe Workfront Operations

Use the Adobe Workfront connector as the source of truth for Workfront data. Do not rely on remembered item state when current data can be retrieved.

## Operating procedure

1. Identify the requested Workfront object, action, and scope. Ask for the minimum missing discriminator when names are ambiguous.
2. Retrieve the current object before recommending or applying a change.
3. Respect the connected user's Workfront access. Do not imply that a missing or inaccessible object does not exist.
4. For read requests, return concise results with object names, statuses, owners or assignees, dates, and identifiers when available.
5. For an explicitly requested create or update, perform the smallest change that satisfies the request and report the resulting object and changed fields.
6. Before deletion, bulk mutation, reassignment, approval decisions, or a materially ambiguous change, summarize the impact and obtain confirmation.
7. After a mutation, retrieve or use the tool response to verify the final state. Report partial failures explicitly.

## Instance and identity behavior

- The connection is bound to the Adobe profile and Workfront instance selected during sign-in.
- If results appear to come from the wrong Preview or Production instance, tell the user to disconnect and reconnect, then choose the intended instance.
- Authentication uses Adobe Identity Management System. In organizations federated with Microsoft Entra ID, follow the organization's Entra sign-in flow when Adobe redirects to it.

## Tool selection

- Prefer targeted retrieval over broad exports.
- Use search or lookup tools before acting when only a human-readable name is provided.
- Use the connector's discovered tool descriptions and input schemas; never invent tool names, fields, statuses, or IDs.
- Treat tool errors and permission denials as authoritative and surface them without claiming success.
