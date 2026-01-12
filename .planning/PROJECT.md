# Invoicing with Integrations Platform

## What This Is

Personal time tracking and invoicing application for independent developers, now being extended with a plugin-based integrations platform. The platform enables bidirectional data sync with banks and external APIs through a clean, extensible plugin architecture that developers can easily extend.

## Core Value

The plugin interface must be simple, well-documented, and hard to get wrong. If developers can't add a new integration in one file with three methods, the architecture has failed.

## Requirements

### Validated

<!-- Existing capabilities from the codebase -->

- ✓ Time tracking with work entries (time-based and fixed amounts) — existing
- ✓ Client and project management with hourly rates — existing
- ✓ Invoice generation from work entries with line items — existing
- ✓ PDF invoice export via Puppeteer/Grover — existing
- ✓ Public client portal with share tokens — existing
- ✓ Dashboard analytics (hours, earnings, trends) — existing
- ✓ Bank payment QR codes (SEPA/EPC for EUR, SPAYD for CZK) — existing
- ✓ i18n support (English, Czech) — existing
- ✓ Session-based authentication with bcrypt — existing
- ✓ Dark mode theming — existing

### Active

<!-- New integrations platform foundation -->

- [ ] Plugin interface contract (name, version, sync method)
- [ ] Plugin registry for discovering and listing available plugins
- [ ] Plugin configuration storage (credentials, settings per plugin)
- [ ] Sync execution engine (manual trigger)
- [ ] Sync history tracking (when, what changed, success/failure, errors)
- [ ] Audit trail for data changes with source attribution
- [ ] Money transactions table for tracking income/expenses from external sources
- [ ] Plugin enable/disable per user setting
- [ ] Example bank integration plugin (demonstrating the interface)
- [ ] Plugin developer documentation

### Out of Scope

- OAuth authentication flows — v1 uses API keys/tokens only, OAuth adds significant complexity
- Scheduled/background sync automation — v1 is manual trigger only
- Third-party plugin marketplace — plugins are bundled with the app
- Multi-tenant plugin isolation — single-user app, no tenant concerns
- Plugin UI components — plugins are backend-only, UI is core app responsibility

## Context

**Existing Architecture:**
- Rails 8.1 monolith with Inertia.js/React frontend
- Service object pattern for business logic (`app/services/`)
- Alba serializers for JSON transformation
- SQLite database with Solid Cache/Queue/Cable
- Single-user application (no multi-tenant)

**Plugin Design Philosophy:**
- Plugins are Ruby classes following a defined interface
- Minimal contract: name, version, sync() method
- State tracking: sync history with timestamps, results, errors
- Data access: plugins can access any model but all changes are audited
- Debugging: full sync history with what changed and any errors

**First Use Case:**
- Connect bank API to fetch transactions
- Match transactions to invoices to verify payment status
- Track income/expenses in new money_transactions table

## Constraints

- **Tech stack**: Rails patterns only — ActiveRecord, concerns, service objects. No external frameworks or gems for plugin loading.
- **Simplicity**: No metaprogramming magic. Explicit registration over clever discovery. Code should be readable without framework knowledge.
- **Test coverage**: Plugin interface must be thoroughly tested. Example plugin serves as both documentation and test fixture.
- **Audit**: Every data change from a plugin must record its source. Non-negotiable for data trust.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Ruby class interface over separate services | Keeps plugins simple, no IPC overhead, fits Rails patterns | — Pending |
| Manual sync trigger for v1 | Simpler than background jobs, user controls when sync happens | — Pending |
| API keys over OAuth for v1 | OAuth adds significant complexity, defer until needed | — Pending |
| Full data access with audit trail | Flexibility for plugins, trust via audit logging | — Pending |
| New money_transactions table | Clean separation from work entries, tracks external money flows | — Pending |

---
*Last updated: 2026-01-12 after initialization*
