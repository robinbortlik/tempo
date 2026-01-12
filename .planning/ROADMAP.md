# Roadmap: Integrations Platform

## Overview

Build a plugin-based integrations platform that enables bidirectional data sync with banks and external APIs. The architecture prioritizes simplicity—plugins are Ruby classes with a minimal contract (name, version, sync method). The journey starts with database infrastructure, builds up the plugin system layer by layer, adds UI for configuration, and culminates in a reference bank integration plugin.

## Domain Expertise

None

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Foundation** - Database schema for plugin infrastructure ✓
- [x] **Phase 2: Plugin Interface** - Core plugin contract and base class ✓
- [x] **Phase 3: Plugin Registry** - Discovery and listing of available plugins
- [x] **Phase 4: Plugin Configuration** - Credential and settings storage per plugin
- [x] **Phase 5: Sync Engine** - Execution engine for running plugin syncs
- [x] **Phase 6: Audit Trail** - Data change tracking with source attribution
- [ ] **Phase 7: Plugin Management UI** - Frontend for enabling/configuring plugins
- [ ] **Phase 8: Example Plugin** - Bank integration reference implementation with documentation

## Phase Details

### Phase 1: Foundation
**Goal**: Create database tables for sync_histories, money_transactions, and plugin_configurations
**Depends on**: Nothing (first phase)
**Research**: Unlikely (database migrations, established Rails patterns)
**Plans**: TBD

Plans:
- [x] 01-01: Database migrations for core tables ✓

### Phase 2: Plugin Interface
**Goal**: Define the plugin base class and contract (name, version, sync method)
**Depends on**: Phase 1
**Research**: Unlikely (Ruby class interface design, internal patterns)
**Plans**: TBD

Plans:
- [x] 02-01: Plugin base class with interface contract ✓

### Phase 3: Plugin Registry
**Goal**: Create registry for discovering and listing available plugins
**Depends on**: Phase 2
**Research**: Unlikely (file discovery, internal patterns)
**Plans**: TBD

Plans:
- [x] 03-01: Plugin registry service

### Phase 4: Plugin Configuration
**Goal**: Store and retrieve plugin credentials and settings per user
**Depends on**: Phase 3
**Research**: Unlikely (encrypted credentials, Rails patterns)
**Plans**: TBD

Plans:
- [x] 04-01: Plugin configuration storage and retrieval

### Phase 5: Sync Engine
**Goal**: Execute plugin syncs with manual trigger, track results
**Depends on**: Phase 4
**Research**: Unlikely (service objects, established patterns)
**Plans**: TBD

Plans:
- [x] 05-01: Sync execution service
- [x] 05-02: Sync history recording

### Phase 6: Audit Trail
**Goal**: Track all data changes from plugins with source attribution
**Depends on**: Phase 5
**Research**: Unlikely (audit concerns, Rails callbacks)
**Plans**: TBD

Plans:
- [x] 06-01: Audit trail implementation ✓

### Phase 7: Plugin Management UI
**Goal**: React UI for viewing, enabling, and configuring plugins
**Depends on**: Phase 6
**Research**: Unlikely (React/Inertia patterns already established)
**Plans**: TBD

Plans:
- [ ] 07-01: Plugin list and enable/disable UI
- [ ] 07-02: Plugin configuration forms
- [ ] 07-03: Sync history display

### Phase 8: Example Plugin
**Goal**: Reference bank integration plugin with developer documentation
**Depends on**: Phase 7
**Research**: Likely (bank API patterns)
**Research topics**: Common bank API structures, transaction data formats, mock implementation patterns
**Plans**: TBD

Plans:
- [ ] 08-01: Example bank plugin implementation
- [ ] 08-02: Plugin developer documentation

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 1/1 | Complete | 2026-01-12 |
| 2. Plugin Interface | 1/1 | Complete | 2026-01-12 |
| 3. Plugin Registry | 1/1 | Complete | 2026-01-12 |
| 4. Plugin Configuration | 1/1 | Complete | 2026-01-12 |
| 5. Sync Engine | 2/2 | Complete | 2026-01-12 |
| 6. Audit Trail | 1/1 | Complete | 2026-01-12 |
| 7. Plugin Management UI | 0/3 | Not started | - |
| 8. Example Plugin | 0/2 | Not started | - |
