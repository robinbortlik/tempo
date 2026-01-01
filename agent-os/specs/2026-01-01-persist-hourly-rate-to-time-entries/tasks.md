# Task Breakdown: Persist Hourly Rate to Time Entries

## Overview
Total Tasks: 14

This feature stores the effective hourly rate on time-based work entries at creation time, preserving historical rates while allowing user overrides.

## Task List

### Backend Foundation

#### Task Group 1: Database and Model Layer
**Dependencies:** None

- [x] 1.0 Complete database and model changes
  - [x] 1.1 Write 4-6 focused tests for hourly_rate model behavior
    - Test auto-population of hourly_rate from project.effective_hourly_rate on create
    - Test hourly_rate not overwritten when user provides explicit value
    - Test calculated_amount uses stored hourly_rate when present
    - Test calculated_amount falls back to project rate when hourly_rate is null
    - Test validation prevents hourly_rate change on invoiced entries
    - Test callback only populates for time-based entries (not fixed)
  - [x] 1.2 Create migration to add hourly_rate column to work_entries
    - Add `hourly_rate` column with type `decimal(10,2)`, nullable
    - Use reversible `change` method
    - No index needed (column not used in queries)
    - Reference: `/Users/robinbortlik/projects/invoicing/db/migrate/20251231162742_add_default_vat_rate_to_clients.rb`
  - [x] 1.3 Add before_validation callback to auto-populate hourly_rate
    - Add callback after existing `detect_entry_type` callback
    - Only populate for time-based entries (`entry_type == 'time'`)
    - Only populate if `hourly_rate.blank?` (allows user override)
    - Set from `project.effective_hourly_rate`
    - File: `/Users/robinbortlik/projects/invoicing/app/models/work_entry.rb`
  - [x] 1.4 Update calculated_amount method to use stored rate
    - Return `amount` if present (existing behavior)
    - Use stored `hourly_rate` when present: `hours * hourly_rate`
    - Fallback to `project.effective_hourly_rate` if `hourly_rate` is null
    - File: `/Users/robinbortlik/projects/invoicing/app/models/work_entry.rb`
  - [x] 1.5 Add validation to prevent rate changes on invoiced entries
    - Add custom validation method `hourly_rate_locked_when_invoiced`
    - Only check if `hourly_rate_changed?` and `invoiced?`
    - Add error to `:hourly_rate` field
    - File: `/Users/robinbortlik/projects/invoicing/app/models/work_entry.rb`
  - [x] 1.6 Ensure model tests pass
    - Run ONLY the 4-6 tests written in 1.1
    - Verify migration runs successfully
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- Migration adds hourly_rate column successfully
- Callback auto-populates rate for time entries on create/update
- User-provided rate is preserved (not overwritten)
- calculated_amount uses stored rate with fallback to project rate
- Invoiced entries cannot have hourly_rate modified

---

### API Layer

#### Task Group 2: Controller Updates
**Dependencies:** Task Group 1

- [x] 2.0 Complete controller changes
  - [x] 2.1 Write 2-3 focused tests for controller behavior
    - Test hourly_rate is permitted in work_entry_params
    - Test hourly_rate is included in work_entry_json response
    - Test hourly_rate is included in work_entry_list_json response
  - [x] 2.2 Add :hourly_rate to work_entry_params
    - Add `:hourly_rate` to permitted params list
    - File: `/Users/robinbortlik/projects/invoicing/app/controllers/work_entries_controller.rb` (line 85)
  - [x] 2.3 Add hourly_rate to JSON response methods
    - Add `hourly_rate: entry.hourly_rate` to `work_entry_json` method
    - Add `hourly_rate: entry.hourly_rate` to `work_entry_list_json` method
    - Keep existing `effective_hourly_rate` from project for reference
    - File: `/Users/robinbortlik/projects/invoicing/app/controllers/work_entries_controller.rb`
  - [x] 2.4 Ensure controller tests pass
    - Run ONLY the 2-3 tests written in 2.1
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- hourly_rate is permitted in create/update params
- hourly_rate is returned in all JSON responses for work entries
- effective_hourly_rate from project still available for form display

---

### Frontend Implementation

#### Task Group 3: Form UI with Collapsible Rate Override
**Dependencies:** Task Group 2

- [x] 3.0 Complete frontend form changes
  - [x] 3.1 Write 3-4 focused tests for rate override UI behavior
    - Test collapsible section only shows when hours field has value
    - Test collapsed state shows current rate text
    - Test expanded state shows rate input field
    - Test rate input is disabled when entry is invoiced
  - [x] 3.2 Add hourly_rate state to WorkEntryForm
    - Add `hourly_rate` to formData state (string, from workEntry prop)
    - Add `showRateOverride` boolean state (default: false)
    - Update WorkEntry interface to include `hourly_rate`, `status`, `effective_hourly_rate`
    - File: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/WorkEntries/Form.tsx`
  - [x] 3.3 Add collapsible rate override section
    - Import Collapsible components from `@/components/ui/collapsible`
    - Add section below hours/amount row
    - Only render when `formData.hours` has a value
    - Reference pattern: `/Users/robinbortlik/projects/invoicing/app/frontend/pages/Reports/components/ProjectGroup.tsx`
  - [x] 3.4 Implement collapsed trigger display
    - Show text: "Rate: $X/h (from project)" when hourly_rate empty
    - Show text: "Rate: $X/h (custom)" when hourly_rate is set
    - Get project's effective_hourly_rate from selected project in projects prop
    - Add expand/collapse chevron icon
  - [x] 3.5 Implement expanded content with rate input
    - Show numeric input with step="0.01" for rate override
    - Pre-populate with current hourly_rate or project's effective_hourly_rate
    - Add helper text explaining how to revert to project rate (clear field)
    - Disable input entirely when entry status is "invoiced"
  - [x] 3.6 Update form submission to include hourly_rate
    - Include hourly_rate in entryData when explicitly set
    - Send null/undefined when cleared to trigger auto-population
  - [x] 3.7 Ensure frontend tests pass
    - Run ONLY the 3-4 tests written in 3.1
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- Collapsible appears only for time-based entries (hours field has value)
- Collapsed state shows current rate with source indication
- Expanded state allows rate override input
- Invoiced entries show locked/disabled rate field
- Clearing rate field reverts to project rate on save

---

### Data Migration

#### Task Group 4: Backfill Existing Entries
**Dependencies:** Task Group 1

- [x] 4.0 Complete data backfill
  - [x] 4.1 Write 2 focused tests for backfill migration
    - Test existing time entries get hourly_rate populated from project.effective_hourly_rate
    - Test fixed entries are not modified (hourly_rate remains null)
  - [x] 4.2 Create data migration to backfill hourly_rate
    - Process entries in batches of 1000 to avoid memory issues
    - Only update entries where `hourly_rate IS NULL AND entry_type = 0` (time entries)
    - Set hourly_rate to project.effective_hourly_rate for each entry
    - Make migration reversible (down sets hourly_rate back to null)
  - [x] 4.3 Ensure backfill tests pass
    - Run ONLY the 2 tests written in 4.1
    - Verify backfill migration completes successfully
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- All existing time-based entries have hourly_rate populated
- Fixed-amount entries are unchanged
- Migration is reversible
- Batching prevents memory issues

---

### Testing

#### Task Group 5: Test Review and Gap Analysis
**Dependencies:** Task Groups 1-4

- [x] 5.0 Review existing tests and fill critical gaps only
  - [x] 5.1 Review tests from Task Groups 1-4
    - Review 4-6 model tests from Task 1.1
    - Review 2-3 controller tests from Task 2.1
    - Review 3-4 frontend tests from Task 3.1
    - Review 2 backfill tests from Task 4.1
    - Total existing tests: approximately 11-15 tests
  - [x] 5.2 Analyze test coverage gaps for this feature only
    - Identify any critical user workflows lacking coverage
    - Focus ONLY on gaps related to hourly_rate persistence
    - Prioritize end-to-end flows over additional unit tests
  - [x] 5.3 Write up to 5 additional tests maximum if needed
    - Consider integration test: create entry, verify rate saved, change project rate, verify entry unchanged
    - Consider integration test: edit entry with custom rate, verify override preserved
    - Skip exhaustive edge case coverage
  - [x] 5.4 Run feature-specific tests only
    - Run all tests from 1.1, 2.1, 3.1, 4.1, and any added in 5.3
    - Expected total: approximately 11-20 tests maximum
    - Do NOT run the entire application test suite
    - Verify all critical workflows pass

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 11-20 tests total)
- Critical user workflows for hourly rate persistence are covered
- No more than 5 additional tests added when filling gaps
- Testing focused exclusively on this feature's requirements

---

## Execution Order

Recommended implementation sequence:

1. **Task Group 1: Database and Model Layer** - Foundation for all other changes
2. **Task Group 4: Backfill Existing Entries** - Can run in parallel with Task Group 2 after Task Group 1
3. **Task Group 2: Controller Updates** - Depends on model changes
4. **Task Group 3: Frontend Implementation** - Depends on controller returning hourly_rate
5. **Task Group 5: Test Review and Gap Analysis** - Final validation after all implementation complete

**Parallel Opportunities:**
- Task Groups 2 and 4 can be worked on in parallel after Task Group 1 completes
