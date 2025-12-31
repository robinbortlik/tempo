# Task Breakdown: Unified Work Logging

## Overview
Total Tasks: 6 Task Groups

This feature replaces the current time-only tracking system with a unified WorkEntry model supporting both hourly (time-based) and fixed-price entries, with improved invoice generation that aggregates time entries per project while showing fixed items individually.

## Task List

### Database Layer

#### Task Group 1: Data Models and Migrations
**Dependencies:** None

- [x] 1.0 Complete database layer for unified work logging
  - [x] 1.1 Write 4-6 focused tests for WorkEntry and InvoiceLineItem models
    - Test WorkEntry entry_type auto-detection (hours only, amount only, both)
    - Test WorkEntry validation (at least one of hours OR amount required)
    - Test WorkEntry `calculated_amount` method
    - Test InvoiceLineItem associations and type checking methods
    - Test join table prevents duplicate work entry links
  - [x] 1.2 Create migration to rename time_entries to work_entries and add new fields
    - Rename table: `time_entries` -> `work_entries`
    - Add column: `entry_type` (integer enum: time=0/fixed=1, default 0, not null)
    - Add column: `amount` (decimal 12,2, nullable)
    - Change column: `hours` from not null to nullable
    - Add index on `entry_type`
    - Reference: `/Users/robinbortlik/projects/invoicing/db/schema.rb` lines 111-125
  - [x] 1.3 Create WorkEntry model (replaces TimeEntry)
    - File: `/Users/robinbortlik/projects/invoicing/app/models/work_entry.rb`
    - Associations: `belongs_to :project`, `has_many :invoice_line_items, through: :invoice_line_item_work_entries`
    - Enum: `entry_type` { time: 0, fixed: 1 }
    - Enum: `status` { unbilled: 0, invoiced: 1 }
    - Validations: presence of date, description, project; at least one of hours/amount
    - Callback: `before_validation :detect_entry_type`
    - Scopes: `for_date_range`, `by_entry_type`
    - Method: `calculated_amount` returns custom amount if set, else hours * project.effective_hourly_rate
    - Reference: `/Users/robinbortlik/projects/invoicing/app/models/time_entry.rb`
  - [x] 1.4 Create migration for invoice_line_items table
    - Fields: invoice_id (required FK), line_type (integer enum), description (text required), quantity (decimal 8,2 nullable), unit_price (decimal 10,2 nullable), amount (decimal 12,2 required), position (integer required)
    - Add index on invoice_id
    - Add foreign key to invoices
  - [x] 1.5 Create InvoiceLineItem model
    - File: `/Users/robinbortlik/projects/invoicing/app/models/invoice_line_item.rb`
    - Associations: `belongs_to :invoice`, `has_many :work_entries, through: :invoice_line_item_work_entries`
    - Enum: `line_type` { time_aggregate: 0, fixed: 1 }
    - Validations: presence of description, amount, position
    - Methods: `time_aggregate?`, `fixed?` (via enum)
    - Default scope: `order(:position)`
  - [x] 1.6 Create migration for invoice_line_item_work_entries join table
    - Fields: invoice_line_item_id (FK), work_entry_id (FK)
    - Add unique index on [invoice_line_item_id, work_entry_id]
    - Add foreign keys to both tables
  - [x] 1.7 Create InvoiceLineItemWorkEntry join model
    - File: `/Users/robinbortlik/projects/invoicing/app/models/invoice_line_item_work_entry.rb`
    - Associations: `belongs_to :invoice_line_item`, `belongs_to :work_entry`
  - [x] 1.8 Update Invoice model associations
    - File: `/Users/robinbortlik/projects/invoicing/app/models/invoice.rb`
    - Add: `has_many :line_items, class_name: 'InvoiceLineItem', dependent: :destroy`
    - Keep existing `has_many :time_entries` temporarily for migration compatibility
    - Update `calculate_totals` to use line_items
  - [x] 1.9 Create data migration for existing TimeEntry records
    - Set entry_type = 'time' for all existing records
    - No changes needed to hours/amount (existing records have hours, no amount)
  - [x] 1.10 Remove TimeEntry model file after migration
    - Delete: `/Users/robinbortlik/projects/invoicing/app/models/time_entry.rb`
  - [x] 1.11 Ensure database layer tests pass
    - Run the 4-6 tests written in 1.1
    - Verify all migrations run successfully

**Acceptance Criteria:**
- WorkEntry model correctly detects entry_type based on hours/amount input
- WorkEntry validates at least one of hours or amount is present
- InvoiceLineItem has proper associations and type methods
- Join table prevents duplicate links
- All migrations are reversible

---

### Backend Services

#### Task Group 2: Business Logic Services
**Dependencies:** Task Group 1

- [x] 2.0 Complete backend services for work entry and invoice handling
  - [x] 2.1 Write 4-6 focused tests for InvoiceBuilder service updates
    - Test preview returns line_items structure (time_aggregate and fixed)
    - Test create_draft creates InvoiceLineItems and links work entries
    - Test time entries aggregated by project into single line item
    - Test fixed entries create individual line items
    - Test handling of empty date range
  - [x] 2.2 Update InvoiceBuilder service for new models
    - File: `/Users/robinbortlik/projects/invoicing/app/services/invoice_builder.rb`
    - Update `unbilled_entries` to query WorkEntry instead of TimeEntry
    - Update `preview` to return line_items structure grouped by project
    - Update `create_draft` to create InvoiceLineItems and link via join table
    - Time entries: aggregate by project with format "Project Name - Xh @ $Y/h"
    - Fixed entries: create individual line items
    - Update `total_hours` and `total_amount` calculations for new entry types
  - [x] 2.3 Add line item aggregation logic to InvoiceBuilder
    - Group time entries by project
    - Calculate aggregate totals per project
    - Maintain individual fixed entries
    - Set proper position values for ordering
  - [x] 2.4 Add support for empty date range in InvoiceBuilder
    - Allow invoice creation with empty date range
    - Return empty line_items array instead of error
    - Support adding manual line items later
  - [x] 2.5 Ensure service tests pass
    - Run the 4-6 tests written in 2.1
    - Verify InvoiceBuilder handles both entry types correctly

**Acceptance Criteria:**
- InvoiceBuilder correctly aggregates time entries per project
- Fixed entries appear as individual line items
- Preview returns proper line_items structure
- Draft creation links work entries via join table

---

### Controllers & API

#### Task Group 3: Controllers and Routes
**Dependencies:** Task Group 2

- [x] 3.0 Complete controller layer for work entries and invoices
  - [x] 3.1 Write 4-6 focused tests for WorkEntriesController
    - Test index returns entries with entry_type field
    - Test create with hours only (time entry)
    - Test create with amount only (fixed entry)
    - Test filtering by entry_type
    - Test update prevents editing invoiced entries
  - [x] 3.2 Create WorkEntriesController (replaces TimeEntriesController)
    - File: `/Users/robinbortlik/projects/invoicing/app/controllers/work_entries_controller.rb`
    - Actions: index, show, new, edit, create, update, destroy, bulk_destroy
    - Strong params: project_id, date, description, hours, amount
    - Reference: `/Users/robinbortlik/projects/invoicing/app/controllers/time_entries_controller.rb`
  - [x] 3.3 Update JSON serialization in WorkEntriesController
    - Include entry_type and amount in JSON responses
    - Update `work_entry_list_json` method
    - Update `work_entry_json` method
    - Update `entries_grouped_by_date` for both entry types
  - [x] 3.4 Add entry_type filter to WorkEntriesController
    - Add entry_type to `current_filters`
    - Update `filtered_work_entries` to filter by entry_type
    - Add summary stats calculation (total hours, total amount)
  - [x] 3.5 Update routes from time_entries to work_entries
    - File: `/Users/robinbortlik/projects/invoicing/config/routes.rb`
    - Replace `resources :time_entries` with `resources :work_entries`
    - Add collection route for bulk_destroy
  - [x] 3.6 Update InvoicesController for line items
    - Update show action to include line_items grouped by project
    - Update JSON serialization for line_items display
    - Reference: `/Users/robinbortlik/projects/invoicing/app/controllers/invoices_controller.rb`
  - [x] 3.7 Add draft invoice line item management endpoints
    - Add nested routes for line_items under invoices
    - Actions: create (add manual line item), update (edit description/amount), destroy (remove line item), reorder (update position)
    - Unlink work entries when removing line item
    - Recalculate invoice totals on changes
  - [x] 3.8 Delete TimeEntriesController
    - Remove: `/Users/robinbortlik/projects/invoicing/app/controllers/time_entries_controller.rb`
  - [x] 3.9 Ensure controller tests pass
    - Run the 4-6 tests written in 3.1
    - Verify CRUD operations work for both entry types

**Acceptance Criteria:**
- WorkEntriesController handles both time and fixed entries
- Routes updated from /time_entries to /work_entries
- Entry type filtering works correctly
- Line item management endpoints functional

---

### Frontend - Log Work Page

#### Task Group 4: Log Work Page (replaces Time Entries)
**Dependencies:** Task Group 3

- [x] 4.0 Complete Log Work frontend page
  - [x] 4.1 Write 3-5 focused tests for work entry components
    - Test QuickEntryForm renders amount field
    - Test entry type detection based on field input
    - Test FilterBar includes entry_type filter
    - Test work entry list displays type badges
  - [x] 4.2 Rename TimeEntries page directory to WorkEntries
    - Rename: `app/frontend/pages/TimeEntries` -> `app/frontend/pages/WorkEntries`
    - Update all imports in page components
  - [x] 4.3 Update QuickEntryForm with Amount field
    - File: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/WorkEntries/components/QuickEntryForm.tsx`
    - Add optional Amount input field
    - Update validation: at least one of hours or amount required
    - Update form submission to `/work_entries` endpoint
    - Reference: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/TimeEntries/components/QuickEntryForm.tsx`
  - [x] 4.4 Update FilterBar with entry_type filter
    - File: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/WorkEntries/components/FilterBar.tsx`
    - Add entry_type dropdown (All, Time, Fixed)
    - Update filter application logic
    - Reference: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/TimeEntries/components/FilterBar.tsx`
  - [x] 4.5 Update work entries list display
    - File: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/WorkEntries/Index.tsx`
    - Add visual badge/icon for entry type (time vs fixed)
    - Display amount for fixed entries instead of hours
    - Add summary stats bar (total hours, total amount for filtered view)
  - [x] 4.6 Update navigation and page header
    - Change "Time Entries" to "Log Work" in navigation
    - Update page title and description
  - [x] 4.7 Update Edit and New pages for work entries
    - Update form fields to include optional amount
    - Update validation logic
    - Update routes to /work_entries
  - [x] 4.8 Ensure frontend component tests pass
    - Run the 3-5 tests written in 4.1
    - Verify components render correctly

**Acceptance Criteria:**
- QuickEntryForm accepts both hours and amount
- Entry type correctly detected from input
- List shows visual distinction between entry types
- Filtering by entry type works
- Summary stats displayed

---

### Frontend - Invoices

#### Task Group 5: Invoice Pages Updates
**Dependencies:** Task Group 4

- [x] 5.0 Complete invoice frontend updates
  - [x] 5.1 Write 3-5 focused tests for invoice components
    - Test invoice preview displays line items grouped by project
    - Test line item editing in draft mode
    - Test add/remove line item functionality
    - Test reorder line items via position buttons
  - [x] 5.2 Update InvoicePreview component for line items
    - Update to display line_items instead of individual time entries
    - Time aggregate lines: show "Project - Xh @ $Y/h = $Z"
    - Fixed lines: show description and amount only
    - Group by project with clear hierarchy
  - [x] 5.3 Update Invoices/New.tsx for line items preview
    - File: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/Invoices/New.tsx`
    - Update preview to show line_items structure
    - Handle empty date range case (show message, allow manual entry)
    - Reference existing file for patterns
  - [x] 5.4 Update Invoices/Show.tsx for line items display
    - File: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/Invoices/Show.tsx`
    - Replace time_entries table with line_items display
    - Group line items by project
    - Time aggregate: show hours, rate, total
    - Fixed: show description and amount
    - Reference existing file for patterns
  - [x] 5.5 Add draft invoice editing capabilities
    - Add line item edit button (description, amount)
    - Add line item remove button (with confirmation)
    - Add manual line item creation
    - Add reorder buttons (up/down) using position field
    - Show auto-recalculated totals
  - [x] 5.6 Create LineItemEditor component
    - File: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/Invoices/components/LineItemEditor.tsx`
    - Inline editing for description and amount
    - Save/cancel buttons
    - Proper form validation
  - [x] 5.7 Ensure invoice component tests pass
    - Run the 3-5 tests written in 5.1
    - Verify invoice display and editing works

**Acceptance Criteria:**
- Invoice preview shows line items, not individual entries
- Time entries aggregated by project
- Fixed entries shown individually
- Draft editing allows add/remove/edit/reorder line items
- Totals recalculate automatically

---

### Testing

#### Task Group 6: Test Review and Gap Analysis
**Dependencies:** Task Groups 1-5

- [x] 6.0 Review existing tests and fill critical gaps only
  - [x] 6.1 Review tests from Task Groups 1-5
    - Review 4-6 model tests from Task 1.1
    - Review 4-6 service tests from Task 2.1
    - Review 4-6 controller tests from Task 3.1
    - Review 3-5 frontend component tests from Tasks 4.1 and 5.1
    - Total existing tests: approximately 18-28 tests
  - [x] 6.2 Analyze test coverage gaps for this feature only
    - Check end-to-end workflow: create work entry -> create invoice -> finalize
    - Verify entry type detection edge cases covered
    - Check line item manipulation flow
    - Focus ONLY on this spec's feature requirements
  - [x] 6.3 Write up to 8 additional tests to fill critical gaps
    - Focus on integration points between models
    - Test complete invoice creation workflow with mixed entry types
    - Test line item unlinking when removing from draft
    - Skip exhaustive edge case testing
  - [x] 6.4 Run feature-specific tests only
    - Run all tests related to WorkEntry, InvoiceLineItem models
    - Run InvoiceBuilder service tests
    - Run WorkEntriesController and InvoicesController request tests
    - Run frontend component tests for WorkEntries and Invoices pages
    - Expected total: approximately 26-36 tests maximum
    - Verify all critical workflows pass

**Acceptance Criteria:**
- All feature-specific tests pass
- Critical user workflows covered (log work -> invoice -> finalize)
- No more than 8 additional tests added
- Testing focused on this feature only

---

## Execution Order

Recommended implementation sequence:
1. **Task Group 1: Database Layer** - Models and migrations first
2. **Task Group 2: Backend Services** - InvoiceBuilder updates
3. **Task Group 3: Controllers & API** - WorkEntriesController and route changes
4. **Task Group 4: Frontend - Log Work** - New unified work logging page
5. **Task Group 5: Frontend - Invoices** - Updated invoice creation and display
6. **Task Group 6: Testing** - Final test review and gap filling

## Key Files Reference

### Models (to create/modify)
- `/Users/robinbortlik/projects/invoicing/app/models/work_entry.rb` (new)
- `/Users/robinbortlik/projects/invoicing/app/models/invoice_line_item.rb` (new)
- `/Users/robinbortlik/projects/invoicing/app/models/invoice_line_item_work_entry.rb` (new)
- `/Users/robinbortlik/projects/invoicing/app/models/invoice.rb` (update)
- `/Users/robinbortlik/projects/invoicing/app/models/time_entry.rb` (delete)

### Controllers (to create/modify)
- `/Users/robinbortlik/projects/invoicing/app/controllers/work_entries_controller.rb` (new)
- `/Users/robinbortlik/projects/invoicing/app/controllers/invoices_controller.rb` (update)
- `/Users/robinbortlik/projects/invoicing/app/controllers/time_entries_controller.rb` (delete)

### Services (to modify)
- `/Users/robinbortlik/projects/invoicing/app/services/invoice_builder.rb` (update)

### Frontend Pages (to create/modify)
- `/Users/robinbortlik/projects/invoicing/app/frontend/pages/WorkEntries/` (rename from TimeEntries)
- `/Users/robinbortlik/projects/invoicing/app/frontend/pages/Invoices/New.tsx` (update)
- `/Users/robinbortlik/projects/invoicing/app/frontend/pages/Invoices/Show.tsx` (update)
- `/Users/robinbortlik/projects/invoicing/app/frontend/pages/Invoices/components/LineItemEditor.tsx` (new)

### Routes
- `/Users/robinbortlik/projects/invoicing/config/routes.rb` (update)
