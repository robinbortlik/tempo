# FIO Bank Plugin - Requirements

## Overview

Integration with FIO bank API using the `fio_api` gem to automatically sync bank transactions, categorize them as income/expense, and match payments to invoices.

## User Requirements

### 1. Transaction Synchronization

**Requirement**: Pull transactions from FIO bank API and store them as `MoneyTransaction` records.

**Details**:
- Use the `fio_api` gem (https://github.com/14113/fio_api) for API communication
- Follow existing plugin architecture defined in `docs/PLUGIN_DEVELOPMENT.md`
- Store each transaction with:
  - External ID for deduplication
  - Amount and currency
  - Transaction date
  - Counterparty information
  - Reference/variable symbol
  - Raw API response data

### 2. Transaction Categorization

**Requirement**: Automatically categorize transactions as income or expense based on FIO's direction flag.

**Decision**: Use FIO's direction flag
- Credits (incoming) = income
- Debits (outgoing) = expense

### 3. Invoice Matching

**Requirement**: Automatically match incoming transactions to unpaid invoices and mark them as paid.

**Decision**: Exact match on both criteria
- Transaction reference must match invoice number exactly
- Transaction amount must match invoice total amount exactly
- Only match invoices that are in "final" status (not draft)

**Matching Logic**:
1. For each incoming (income) transaction
2. Extract the reference/variable symbol from the transaction
3. Search for an invoice where `reference` matches the transaction reference
4. Verify the amount matches exactly
5. If match found, mark invoice as "paid" with payment date from transaction

### 4. Invoice Paid Status

**Requirement**: Add a new "paid" status to invoices and track when payment was received.

**Decision**: New status enum value
- Add `paid: 2` to the Invoice status enum (draft: 0, final: 1, paid: 2)
- Add `paid_at` timestamp field to track when invoice was marked as paid

**Status Transitions**:
- draft -> final (existing)
- final -> paid (new - via automatic matching or manual action)

### 5. Manual Payment Marking

**Requirement**: Allow users to manually mark invoices as paid.

**Decision**: Modal with date picker
- Add "Mark as Paid" button on invoice show/edit pages
- Clicking opens a modal dialog
- Modal contains a date picker (defaults to current date)
- User selects or confirms the payment date
- Invoice is marked as paid with the selected date

### 6. Automated Sync Scheduling (Cron Orchestrator)

**Requirement**: Create an orchestrator job that runs plugins automatically based on their configured schedules.

**Decision**: Per-plugin schedule configuration
- Each plugin can have its own cron expression stored in `PluginConfiguration.settings`
- Add a `cron_schedule` setting field to plugins
- Create a `PluginSyncOrchestratorJob` that:
  - Runs periodically (e.g., every minute)
  - Checks all enabled plugins
  - Executes sync for plugins whose schedule matches current time
  - Uses Solid Queue for job scheduling

**Schedule Configuration**:
- Setting field: `cron_schedule` (string, e.g., "0 6 * * *" for daily at 6 AM)
- If blank/not set, plugin does not auto-sync (manual only)
- Cron expression format (standard 5-field cron)

### 7. Error Handling

**Requirement**: Handle sync failures appropriately.

**Decision**: Silent logging only
- Record failures in `SyncHistory` table
- Do not send email or UI notifications for failures
- Errors are visible in the plugin sync history UI

## Technical Requirements

### Plugin Implementation

Follow the plugin development guide:
- Create `app/plugins/fio_bank_plugin.rb`
- Inherit from `BasePlugin`
- Implement required methods: `name`, `version`, `description`, `sync`
- Define `credential_fields` for API token
- Define `setting_fields` for sync preferences and cron schedule

### Credential Fields

```ruby
def self.credential_fields
  [
    {
      name: "api_token",
      label: "FIO API Token",
      type: "password",
      required: true,
      description: "API token from FIO internet banking"
    }
  ]
end
```

### Setting Fields

```ruby
def self.setting_fields
  [
    {
      name: "sync_from_date",
      label: "Sync from date",
      type: "date",
      required: false,
      description: "Only import transactions after this date"
    },
    {
      name: "cron_schedule",
      label: "Auto-sync schedule (cron)",
      type: "text",
      required: false,
      description: "Cron expression for automated sync (e.g., '0 6 * * *' for daily at 6 AM)"
    }
  ]
end
```

### Database Changes

1. **Invoice model**:
   - Add `paid: 2` to status enum
   - Add `paid_at:datetime` column

2. **Migration**:
   ```ruby
   add_column :invoices, :paid_at, :datetime
   ```

### API Integration

Using `fio_api` gem:
- API token authentication
- Fetch transactions for date range
- Parse transaction data including:
  - Transaction ID (for external_id)
  - Amount and currency
  - Date
  - Counterparty name and account
  - Variable symbol (reference)
  - Message/description

### Cron Orchestrator Job

Create `PluginSyncOrchestratorJob`:
- Scheduled to run every minute
- Iterates through enabled `PluginConfiguration` records
- Parses `cron_schedule` setting
- Checks if current time matches the schedule
- Executes `SyncExecutionService` for matching plugins
- Handles errors gracefully (one plugin failure doesn't stop others)

## UI Requirements

### Invoice Show Page

- Add "Mark as Paid" button (visible when invoice is "final")
- Button opens modal with:
  - Date picker for payment date (default: today)
  - "Confirm" and "Cancel" buttons
- On confirm: updates invoice status to "paid" and sets `paid_at`

### Invoice Index/List

- Show "paid" status badge for paid invoices
- Distinguish visually between final (unpaid) and paid invoices

### Plugin Settings

- Add `cron_schedule` field to plugin configuration form
- Show next scheduled run time based on cron expression (nice to have)

## Acceptance Criteria

1. **FIO Plugin Sync**:
   - [ ] Plugin appears in Settings > Plugins list
   - [ ] Can configure API token
   - [ ] Manual sync pulls transactions from FIO
   - [ ] Transactions stored as `MoneyTransaction` records
   - [ ] Incoming = income, outgoing = expense
   - [ ] Duplicate transactions are not created (external_id deduplication)

2. **Invoice Matching**:
   - [ ] Incoming transactions with matching reference + amount mark invoices as paid
   - [ ] Invoice `paid_at` is set to transaction date
   - [ ] Only "final" invoices are matched (not drafts)

3. **Manual Payment**:
   - [ ] "Mark as Paid" button visible on final invoices
   - [ ] Modal opens with date picker
   - [ ] Selecting date and confirming marks invoice as paid
   - [ ] `paid_at` is set to selected date

4. **Automated Sync**:
   - [ ] Plugins can have `cron_schedule` setting
   - [ ] Orchestrator job runs enabled plugins on schedule
   - [ ] Sync failures are logged but don't crash orchestrator

5. **Status Display**:
   - [ ] Invoice list shows paid/unpaid status clearly
   - [ ] Invoice detail shows payment date when paid

## Out of Scope (v1)

- Partial payment support
- Payment notifications (email/UI)
- Multiple bank account support per plugin instance
- Fuzzy/partial reference matching
- Outgoing payment reconciliation
