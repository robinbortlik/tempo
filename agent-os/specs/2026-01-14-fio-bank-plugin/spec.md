# Specification: FIO Bank Plugin

## Goal
Integrate with FIO bank API to automatically sync bank transactions, categorize them as income/expense, and match incoming payments to invoices to mark them as paid.

## User Stories
- As a user, I want to sync my FIO bank transactions automatically so that I have a complete financial record
- As a user, I want incoming payments to automatically mark my invoices as paid so that I do not need to manually track payments

## Specific Requirements

**FIO Plugin Implementation**
- Create `app/plugins/fio_bank_plugin.rb` inheriting from `BasePlugin`
- Implement `name` returning `"fio_bank"`, `version` returning `"1.0.0"`, and `description`
- Define `credential_fields` with `api_token` (password, required)
- Define `setting_fields` with `sync_from_date` (date, optional) and `cron_schedule` (text, optional)
- Use the `fio_api` gem for API communication

**Transaction Sync Logic**
- Fetch transactions using `FioAPI::List.by_date_range` from `sync_from_date` to today
- Create `MoneyTransaction` records with unique `external_id` from FIO's transaction ID
- Set `transaction_type` to `:income` for credits and `:expense` for debits based on amount sign
- Store counterparty, reference (variable symbol), description, and raw API response
- Use deduplication pattern: find by `source` + `external_id`, update if changed, create if new

**Invoice Paid Status**
- Add `paid: 2` to Invoice status enum (existing: `draft: 0`, `final: 1`)
- Add `paid_at` datetime column to invoices table via migration
- Only "final" invoices can be marked as "paid" (drafts cannot)
- Add scope `Invoice.payable` for invoices in "final" status

**Invoice Matching Service**
- Create `InvoiceMatchingService` to match transactions to invoices
- Match criteria: incoming transaction reference equals invoice number exactly AND amount matches `grand_total` exactly
- Only match invoices in "final" status (not draft, not already paid)
- On match: update invoice `status` to `:paid` and set `paid_at` to transaction date
- Link transaction to invoice via `invoice_id` foreign key

**Manual Payment Marking**
- Add `mark_as_paid` action to `InvoicesController` accepting `paid_at` date parameter
- Guard: only allow marking "final" invoices as paid
- Update invoice status to `:paid` and set `paid_at` field
- Return success/error via redirect with flash message

**Plugin Sync Orchestrator Job**
- Create `PluginSyncOrchestratorJob < ApplicationJob` in `app/jobs/`
- Add recurring schedule in `config/recurring.yml` to run every minute
- Iterate through `PluginConfiguration.enabled` records
- Parse `cron_schedule` setting using the `fugit` gem to evaluate cron expressions
- Execute `SyncExecutionService.execute` for plugins whose schedule matches current time
- Handle errors gracefully: log failures, continue with next plugin

**Cron Schedule Parsing**
- Use `fugit` gem for parsing cron expressions (already dependency of solid_queue)
- Check if current time matches schedule: `Fugit::Cron.parse(expression).match?(Time.current)`
- Skip plugins with blank/invalid cron_schedule (manual sync only)

## Visual Design

No visual mockups provided. UI changes follow existing patterns.

## Existing Code to Leverage

**BasePlugin and Plugin Infrastructure**
- Inherit from `BasePlugin` in `app/plugins/base_plugin.rb`
- Use `credentials` and `settings` helper methods for accessing configuration
- Follow `ExamplePlugin` patterns for sync method implementation and deduplication

**SyncExecutionService**
- Use existing `SyncExecutionService.execute(plugin_name:)` for running syncs
- Service handles validation, audit context, and sync history tracking

**MoneyTransaction Model**
- Use existing model structure with `source`, `external_id`, `amount`, `currency`, `transacted_on`, `transaction_type`, `reference`, `invoice_id`
- Follow existing deduplication pattern: `find_by(source: name, external_id: id)`

**Invoice UI Patterns**
- Follow `StatusBadge` component pattern in `Show.tsx` for paid status badge
- Use `AlertDialog` pattern from finalize/delete for "Mark as Paid" confirmation modal
- Extend existing tab filtering in `Index.tsx` to include paid status

**Plugin Configuration UI**
- `Plugins/Configure.tsx` already handles dynamic field rendering from `credential_fields` and `setting_fields`
- New fields (`cron_schedule`) will automatically render via existing `SettingsForm` component

## Out of Scope
- Partial payment support (amount must match exactly)
- Payment notifications via email or UI alerts
- Multiple bank account support per plugin instance
- Fuzzy or partial reference matching
- Outgoing payment reconciliation
- Automatic retry of failed syncs
- Manual transaction-to-invoice matching UI
- Unpaid status (reverting from paid back to final)
- Currency conversion for matching
- Support for other bank APIs besides FIO
