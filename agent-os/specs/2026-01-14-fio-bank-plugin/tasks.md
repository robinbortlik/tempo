# Task Breakdown: FIO Bank Plugin

## Overview
Total Tasks: 4 Task Groups

This feature adds FIO bank integration to automatically sync transactions, match payments to invoices, and enable manual payment marking.

## Task List

### Database & Model Layer

#### Task Group 1: Invoice Paid Status
**Dependencies:** None

- [x] 1.0 Complete invoice paid status implementation
  - [x] 1.1 Write 3-5 focused tests for Invoice paid status
    - Test that `paid: 2` enum value works correctly
    - Test `paid_at` timestamp is set when marking as paid
    - Test `payable` scope returns only "final" invoices
    - Test status transition from final to paid
  - [x] 1.2 Create migration adding `paid_at` to invoices
    - File: `db/migrate/20260114213237_add_paid_at_to_invoices.rb`
    - Add `paid_at:datetime` column (nullable)
  - [x] 1.3 Update Invoice model with paid status
    - File: `app/models/invoice.rb`
    - Add `paid: 2` to existing status enum: `enum :status, { draft: 0, final: 1, paid: 2 }`
    - Add scope `payable` for invoices in "final" status
  - [x] 1.4 Run database layer tests
    - Run ONLY the tests written in 1.1
    - Verify migration runs successfully

**Acceptance Criteria:**
- Invoice model has `paid` status with value 2
- `paid_at` column exists on invoices table
- `Invoice.payable` scope returns only final invoices

---

### Backend Services & Plugin

#### Task Group 2: FIO Plugin and Invoice Matching
**Dependencies:** Task Group 1

- [ ] 2.0 Complete FIO plugin and invoice matching
  - [ ] 2.1 Write 4-6 focused tests for FIO plugin and matching
    - Test FioBankPlugin class methods (name, version, description)
    - Test sync creates MoneyTransaction records with correct transaction_type
    - Test deduplication by source + external_id
    - Test InvoiceMatchingService matches transactions to invoices by reference + amount
    - Test matched invoices are marked as paid with correct paid_at
  - [ ] 2.2 Add fio_api gem to Gemfile
    - Add `gem "fio_api"` to Gemfile
    - Run `bundle install`
  - [ ] 2.3 Create FioBankPlugin class
    - File: `app/plugins/fio_bank_plugin.rb`
    - Inherit from `BasePlugin`
    - Implement `name` returning `"fio_bank"`
    - Implement `version` returning `"1.0.0"`
    - Implement `description`
    - Define `credential_fields` with `api_token` (password, required)
    - Define `setting_fields` with `sync_from_date` (date, optional) and `cron_schedule` (text, optional)
    - Follow ExamplePlugin pattern in `app/plugins/example_plugin.rb`
  - [ ] 2.4 Implement FioBankPlugin sync method
    - Use `FioAPI::List.by_date_range` for fetching transactions
    - Create MoneyTransaction records with unique `external_id` from FIO transaction ID
    - Set `transaction_type` to `:income` for credits, `:expense` for debits based on amount sign
    - Store counterparty, reference (variable symbol), description, and raw API response
    - Use deduplication pattern: `find_by(source: name, external_id: id)`
  - [ ] 2.5 Create InvoiceMatchingService
    - File: `app/services/invoice_matching_service.rb`
    - Match incoming transactions to invoices by exact reference and amount
    - Only match `Invoice.payable` (final status, not paid)
    - On match: update invoice status to `:paid`, set `paid_at` to transaction date
    - Link transaction to invoice via `invoice_id` foreign key
  - [ ] 2.6 Integrate InvoiceMatchingService into FioBankPlugin
    - Call InvoiceMatchingService after processing transactions
  - [ ] 2.7 Run plugin and service tests
    - Run ONLY the tests written in 2.1
    - Verify FIO plugin sync works (with mocked API)

**Acceptance Criteria:**
- FioBankPlugin appears in plugin list
- Plugin sync creates MoneyTransaction records
- Income/expense correctly assigned based on amount sign
- Matching transactions mark invoices as paid

---

### Background Job & Scheduling

#### Task Group 3: Plugin Sync Orchestrator Job
**Dependencies:** Task Group 2

- [ ] 3.0 Complete plugin sync orchestrator
  - [ ] 3.1 Write 3-4 focused tests for orchestrator job
    - Test job iterates through enabled PluginConfiguration records
    - Test cron schedule parsing with fugit gem
    - Test sync is executed when schedule matches current time
    - Test errors are logged but don't crash orchestrator
  - [ ] 3.2 Create PluginSyncOrchestratorJob
    - File: `app/jobs/plugin_sync_orchestrator_job.rb`
    - Inherit from `ApplicationJob`
    - Iterate through `PluginConfiguration.enabled` records
    - Parse `cron_schedule` setting using `Fugit::Cron.parse(expression).match?(Time.current)`
    - Execute `SyncExecutionService.execute(plugin_name:)` for matching plugins
    - Skip plugins with blank/invalid cron_schedule
    - Handle errors gracefully: log failures, continue with next plugin
  - [ ] 3.3 Add recurring schedule to config/recurring.yml
    - Add job entry to run every minute
    - Configure for all environments (or at minimum production)
  - [ ] 3.4 Run orchestrator job tests
    - Run ONLY the tests written in 3.1

**Acceptance Criteria:**
- PluginSyncOrchestratorJob runs enabled plugins on schedule
- Cron expressions are parsed using fugit gem
- Sync failures are logged but don't crash the job

---

### API & Frontend

#### Task Group 4: Manual Payment Marking
**Dependencies:** Task Group 1

- [ ] 4.0 Complete manual payment marking feature
  - [ ] 4.1 Write 3-5 focused tests for mark_as_paid functionality
    - Test mark_as_paid action on InvoicesController
    - Test only final invoices can be marked as paid (reject drafts)
    - Test paid_at is set to provided date
    - Test UI shows "Mark as Paid" button for final invoices only
  - [ ] 4.2 Add mark_as_paid action to InvoicesController
    - File: `app/controllers/invoices_controller.rb`
    - Accept `paid_at` date parameter
    - Guard: only allow marking "final" invoices as paid
    - Update invoice status to `:paid` and set `paid_at`
    - Return redirect with flash message
  - [ ] 4.3 Add route for mark_as_paid
    - File: `config/routes.rb`
    - Add member route: `post :mark_as_paid`
  - [ ] 4.4 Update Invoice Show page UI
    - File: `app/frontend/pages/Invoices/Show.tsx`
    - Add "Mark as Paid" button (visible when invoice is "final", not "paid")
    - Use AlertDialog pattern from finalize/delete for confirmation modal
    - Add date picker for payment date (default: today)
    - Handle confirmation and submit to mark_as_paid endpoint
  - [ ] 4.5 Update StatusBadge for paid status
    - File: `app/frontend/pages/Invoices/Show.tsx` and `Index.tsx`
    - Add styling for "paid" status badge (distinct from draft/final)
    - Display `paid_at` date on invoice show page when paid
  - [ ] 4.6 Update Invoice Index page filtering
    - File: `app/frontend/pages/Invoices/Index.tsx`
    - Add "paid" tab to filter tabs
    - Update counts to include paid invoices
  - [ ] 4.7 Update InvoiceSerializer
    - Include `paid_at` in serialized data
    - Ensure status "paid" is properly serialized
  - [ ] 4.8 Add translations for paid status
    - Add `pages.invoices.status.paid` translation
    - Add `pages.invoices.markAsPaid.*` translations for modal
  - [ ] 4.9 Run manual payment marking tests
    - Run ONLY the tests written in 4.1

**Acceptance Criteria:**
- "Mark as Paid" button visible on final invoices
- Modal with date picker confirms payment
- Invoice marked as paid with correct paid_at date
- Paid status badge shows in UI
- Invoice list can filter by paid status

---

## Execution Order

Recommended implementation sequence:

1. **Task Group 1: Invoice Paid Status** - Database foundation (no dependencies)
2. **Task Group 2: FIO Plugin and Invoice Matching** - Core sync functionality (depends on 1)
3. **Task Group 3: Plugin Sync Orchestrator Job** - Automated scheduling (depends on 2)
4. **Task Group 4: Manual Payment Marking** - UI for manual payments (depends on 1 only, can run in parallel with 2 & 3)

**Parallel Execution Opportunities:**
- Task Groups 2, 3, and 4 can all start after Task Group 1 completes
- Task Group 4 only depends on Task Group 1 (not 2 or 3)

## Key Files to Create/Modify

### New Files
- `db/migrate/XXXXXX_add_paid_at_to_invoices.rb`
- `app/plugins/fio_bank_plugin.rb`
- `app/services/invoice_matching_service.rb`
- `app/jobs/plugin_sync_orchestrator_job.rb`
- `spec/plugins/fio_bank_plugin_spec.rb`
- `spec/services/invoice_matching_service_spec.rb`
- `spec/jobs/plugin_sync_orchestrator_job_spec.rb`
- `spec/requests/invoices_mark_as_paid_spec.rb`

### Modified Files
- `Gemfile` (add fio_api gem)
- `app/models/invoice.rb` (add paid status, payable scope)
- `app/controllers/invoices_controller.rb` (add mark_as_paid action)
- `config/routes.rb` (add mark_as_paid route)
- `config/recurring.yml` (add orchestrator job schedule)
- `app/frontend/pages/Invoices/Show.tsx` (mark as paid UI)
- `app/frontend/pages/Invoices/Index.tsx` (paid filter tab, badge)
- `app/serializers/invoice_serializer.rb` (add paid_at)
- Translation files for paid status labels

## Reference Patterns

- **Plugin implementation:** Follow `app/plugins/example_plugin.rb` pattern
- **Service objects:** Follow `app/services/sync_execution_service.rb` pattern
- **AlertDialog for confirmation:** Use existing pattern in `Show.tsx` for finalize/delete
- **Status filtering tabs:** Extend existing pattern in `Index.tsx`
- **StatusBadge component:** Extend existing component in `Show.tsx` and `Index.tsx`
