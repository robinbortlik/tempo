# Task Breakdown: Mobile Responsive Design

## Overview
Total Tasks: 7 Task Groups

This task list implements mobile responsive design for all pages in the invoicing application, targeting 375px-390px viewport widths. The implementation follows a mobile-first approach with progressive enhancement for larger screens.

## Task List

### Shared Components

#### Task Group 1: MobileCard Component and Responsive Utilities
**Dependencies:** None

- [x] 1.0 Complete shared mobile components
  - [x] 1.1 Write 4 focused tests for MobileCard component
    - Test MobileCard renders with title and content
    - Test MobileCard onClick navigation behavior
    - Test MobileCard renders secondary details
    - Test MobileCard renders action slot
  - [x] 1.2 Create MobileCard component
    - File: `app/frontend/components/MobileCard.tsx`
    - Props: `title`, `subtitle`, `details` (key-value pairs), `onClick`, `action` (optional slot)
    - Use existing Card primitives from `app/frontend/components/ui/card.tsx`
    - Follow component patterns from `app/frontend/components/` (named export)
    - Include touch-friendly padding (p-4) and min-h-11 for tap targets
  - [x] 1.3 Create PageHeader responsive variant
    - File: `app/frontend/components/PageHeader.tsx`
    - Implement responsive layout: `flex flex-col gap-4 md:flex-row md:items-center md:justify-between`
    - Action button slot with `w-full md:w-auto` styling
    - Props: `title`, `description`, `action` (React node)
  - [x] 1.4 Ensure shared component tests pass
    - Run ONLY the 4 tests written in 1.1

**Files to create/modify:**
- `app/frontend/components/MobileCard.tsx` (new)
- `app/frontend/components/PageHeader.tsx` (new)
- `app/frontend/components/__tests__/MobileCard.test.tsx` (new)

**Acceptance Criteria:**
- MobileCard component renders correctly with all prop combinations
- PageHeader stacks on mobile, horizontal on desktop
- Touch targets are at least 44px height
- Tests pass

---

### Dashboard Page

#### Task Group 2: Dashboard Mobile Responsiveness
**Dependencies:** Task Group 1

- [x] 2.0 Complete Dashboard mobile updates
  - [x] 2.1 Write 3 focused tests for Dashboard mobile layout
    - Test stats grid renders in responsive columns
    - Test UnbilledByClientTable mobile card view renders
    - Test chart containers are responsive
  - [x] 2.2 Update Dashboard/Index.tsx responsive layout
    - File: `app/frontend/pages/Dashboard/Index.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Stats grid already uses `grid-cols-1 md:grid-cols-2 lg:grid-cols-4` - verify working
    - Charts grid: change to `grid-cols-1 lg:grid-cols-2 gap-4 md:gap-6`
  - [x] 2.3 Update UnbilledByClientTable for mobile
    - File: `app/frontend/pages/Dashboard/components/UnbilledByClientTable.tsx`
    - Add mobile card list using MobileCard component: `block md:hidden`
    - Hide desktop Table on mobile: `hidden md:block`
    - Card shows: client name (title), project count (subtitle), hours/amount/rate (details)
  - [x] 2.4 Ensure Dashboard tests pass
    - Run ONLY the 3 tests written in 2.1

**Files to modify:**
- `app/frontend/pages/Dashboard/Index.tsx`
- `app/frontend/pages/Dashboard/components/UnbilledByClientTable.tsx`

**Acceptance Criteria:**
- Dashboard renders without horizontal scroll at 375px
- Stats cards stack on mobile
- Unbilled table shows as cards on mobile
- Charts scale down appropriately

---

### Clients Pages

#### Task Group 3: Clients Mobile Responsiveness
**Dependencies:** Task Group 1

- [x] 3.0 Complete Clients pages mobile updates
  - [x] 3.1 Write 4 focused tests for Clients mobile layout
    - Test Clients/Index mobile card view renders
    - Test Clients/Show stats grid stacks on mobile
    - Test Clients/Show details grid stacks on mobile
    - Test page header stacks on mobile
  - [x] 3.2 Update Clients/Index.tsx for mobile
    - File: `app/frontend/pages/Clients/Index.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Use PageHeader component for header
    - Add mobile card list: `block md:hidden`
    - Hide desktop Table: `hidden md:block`
    - Card shows: name/initials (title), email (subtitle), rate/unbilled/projects (details)
  - [x] 3.3 Update Clients/Show.tsx for mobile
    - File: `app/frontend/pages/Clients/Show.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Header buttons: `w-full md:w-auto` and stack on mobile
    - Stats grid: change `grid-cols-4` to `grid-cols-2 md:grid-cols-4 gap-3 md:gap-4`
    - Details grid: change `grid-cols-2` to `grid-cols-1 md:grid-cols-2 gap-4 md:gap-6`
    - Share link section: stack controls on mobile with `flex-col md:flex-row`
  - [x] 3.4 Update Clients/Form.tsx for mobile (used by New/Edit)
    - File: `app/frontend/pages/Clients/Form.tsx`
    - Form grid: change `grid-cols-2 gap-4` to `grid-cols-1 md:grid-cols-2 gap-4`
    - Full-width inputs on mobile
  - [x] 3.5 Ensure Clients tests pass
    - Run ONLY the 4 tests written in 3.1

**Files to modify:**
- `app/frontend/pages/Clients/Index.tsx`
- `app/frontend/pages/Clients/Show.tsx`
- `app/frontend/pages/Clients/Form.tsx`

**Acceptance Criteria:**
- Clients list shows as cards on mobile
- Client detail page stacks grids vertically
- Forms are full-width on mobile
- No horizontal overflow at 375px

---

### Projects & Invoices Pages

#### Task Group 4: Projects and Invoices Mobile Responsiveness
**Dependencies:** Task Group 1

- [x] 4.0 Complete Projects and Invoices mobile updates
  - [x] 4.1 Write 4 focused tests for Projects/Invoices mobile layout
    - Test Projects/Index project rows are touch-friendly on mobile
    - Test Invoices/Index mobile card view renders
    - Test Invoices/New layout stacks on mobile
    - Test Invoices/Show sections stack on mobile
  - [x] 4.2 Update Projects/Index.tsx for mobile
    - File: `app/frontend/pages/Projects/Index.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Use PageHeader component
    - Project rows: simplify layout on mobile, hide entries count: `hidden md:block`
    - Ensure touch targets (min-h-11)
  - [x] 4.3 Update Invoices/Index.tsx for mobile
    - File: `app/frontend/pages/Invoices/Index.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Use PageHeader component
    - Add mobile card list: `block md:hidden`
    - Hide desktop Table: `hidden md:block`
    - Card shows: invoice number (title), client/period (subtitle), status/amount (details)
    - Tabs should scroll horizontally on mobile if needed
  - [x] 4.4 Update Invoices/New.tsx for mobile
    - File: `app/frontend/pages/Invoices/New.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Change `grid grid-cols-3 gap-8` to `flex flex-col lg:grid lg:grid-cols-3 gap-6 lg:gap-8`
    - Form column: `col-span-1` stays, appears first on mobile
    - Preview column: `col-span-2` stays, appears below form on mobile
    - Date inputs: stack `grid-cols-2` to `grid-cols-1 md:grid-cols-2`
  - [x] 4.5 Update Invoices/Show.tsx for mobile
    - File: `app/frontend/pages/Invoices/Show.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Header buttons: stack with `flex-col md:flex-row gap-2`
    - Invoice details grid: responsive stacking
    - Line items: simplify display on mobile
  - [x] 4.6 Ensure Projects/Invoices tests pass
    - Run ONLY the 4 tests written in 4.1

**Files to modify:**
- `app/frontend/pages/Projects/Index.tsx`
- `app/frontend/pages/Invoices/Index.tsx`
- `app/frontend/pages/Invoices/New.tsx`
- `app/frontend/pages/Invoices/Show.tsx`

**Acceptance Criteria:**
- Projects list is touch-friendly on mobile
- Invoices list shows as cards on mobile
- Invoice creation form stacks with preview below
- No horizontal overflow at 375px

---

### Work Entries Page

#### Task Group 5: Work Entries Mobile Responsiveness
**Dependencies:** Task Group 1

- [x] 5.0 Complete Work Entries mobile updates
  - [x] 5.1 Write 4 focused tests for Work Entries mobile layout
    - Test QuickEntryForm stacks inputs on mobile
    - Test FilterBar controls wrap on mobile
    - Test summary stats bar stacks on mobile
    - Test WorkEntryRow displays condensed on mobile
  - [x] 5.2 Update WorkEntries/Index.tsx for mobile
    - File: `app/frontend/pages/WorkEntries/Index.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Summary stats bar: change to `flex-col md:flex-row` and stack stats
  - [x] 5.3 Update QuickEntryForm for mobile
    - File: `app/frontend/pages/WorkEntries/components/QuickEntryForm.tsx`
    - Change `flex items-end gap-4` to `flex flex-col md:flex-row md:items-end gap-3 md:gap-4`
    - Date/Project row on mobile, Hours/Amount row, Description/Button row
    - Or full stack: each input full-width on mobile
    - Use `grid grid-cols-2 md:grid-cols-6 gap-3` pattern for inputs
    - Button: `w-full md:w-auto`
  - [x] 5.4 Update FilterBar for mobile
    - File: `app/frontend/pages/WorkEntries/components/FilterBar.tsx`
    - Wrap filter controls on mobile using `flex flex-wrap gap-2 md:gap-3`
    - Consider collapsible filters on mobile (optional enhancement)
  - [x] 5.5 Update WorkEntryRow for mobile
    - File: `app/frontend/pages/WorkEntries/components/WorkEntryRow.tsx`
    - Simplify layout on mobile: project/description on one line, date/hours/amount on second
    - Use `flex-col md:flex-row` pattern
    - Action buttons: ensure 44px tap targets
  - [x] 5.6 Ensure Work Entries tests pass
    - Run ONLY the 4 tests written in 5.1

**Files to modify:**
- `app/frontend/pages/WorkEntries/Index.tsx`
- `app/frontend/pages/WorkEntries/components/QuickEntryForm.tsx`
- `app/frontend/pages/WorkEntries/components/FilterBar.tsx`
- `app/frontend/pages/WorkEntries/components/WorkEntryRow.tsx`

**Acceptance Criteria:**
- Quick entry form inputs stack on mobile
- Filter bar wraps controls appropriately
- Work entry rows are readable and touch-friendly
- No horizontal overflow at 375px

---

### Settings Page

#### Task Group 6: Settings Mobile Responsiveness
**Dependencies:** Task Group 1

- [x] 6.0 Complete Settings mobile updates
  - [x] 6.1 Write 2 focused tests for Settings mobile layout
    - Test form sections are full-width on mobile
    - Test grid inputs stack on mobile
  - [x] 6.2 Update Settings/Show.tsx for mobile
    - File: `app/frontend/pages/Settings/Show.tsx`
    - Change page padding: `p-4 md:p-6 lg:p-8`
    - Form max-width: `max-w-2xl` stays for desktop, full-width on mobile
    - All `grid-cols-2 gap-4` to `grid-cols-1 md:grid-cols-2 gap-4`
    - Logo section: stack vertically on mobile with `flex-col md:flex-row`
    - Submit button: `w-full md:w-auto`
  - [x] 6.3 Ensure Settings tests pass
    - Run ONLY the 2 tests written in 6.1

**Files to modify:**
- `app/frontend/pages/Settings/Show.tsx`

**Acceptance Criteria:**
- Form inputs are full-width on mobile
- Logo upload section stacks on mobile
- Submit button is full-width on mobile
- No horizontal overflow at 375px

---

### Visual Testing

#### Task Group 7: Playwright Visual Snapshot Testing
**Dependencies:** Task Groups 1-6

- [ ] 7.0 Complete Playwright visual testing setup
  - [ ] 7.1 Install Playwright and configure
    - Add `@playwright/test` as dev dependency
    - Create `playwright.config.ts` at project root
    - Configure for visual testing only (no full E2E)
    - Set viewport presets: 375px (iPhone SE), 390px (iPhone 14)
  - [ ] 7.2 Create visual test file structure
    - Create directory: `e2e/visual/`
    - Create directory: `e2e/visual/snapshots/` (for baseline images)
    - Create test file: `e2e/visual/mobile-screenshots.spec.ts`
  - [ ] 7.3 Write visual snapshot tests for all pages
    - Test at 375px viewport:
      - Dashboard
      - Clients/Index
      - Clients/Show (with sample client)
      - Projects/Index
      - Invoices/Index
      - Invoices/New
      - Invoices/Show (with sample invoice)
      - WorkEntries/Index
      - Settings/Show
    - Repeat at 390px viewport
    - Use `toHaveScreenshot()` matcher
  - [ ] 7.4 Generate baseline screenshots
    - Run Playwright to generate initial snapshots
    - Verify snapshots show correct mobile layouts
    - Commit baseline snapshots to repository
  - [ ] 7.5 Add npm scripts for visual testing
    - Add to package.json: `"test:visual": "playwright test e2e/visual/"`
    - Add to package.json: `"test:visual:update": "playwright test e2e/visual/ --update-snapshots"`

**Files to create/modify:**
- `package.json` (add @playwright/test dependency and scripts)
- `playwright.config.ts` (new)
- `e2e/visual/mobile-screenshots.spec.ts` (new)
- `e2e/visual/snapshots/` (baseline images)

**Acceptance Criteria:**
- Playwright installed and configured
- Visual tests capture all pages at 375px and 390px
- Baseline screenshots generated and committed
- npm scripts available for running visual tests

---

## Execution Order

Recommended implementation sequence:

1. **Task Group 1: Shared Components** - Create MobileCard and PageHeader components first
2. **Task Group 2: Dashboard** - Update dashboard with shared components
3. **Task Group 3: Clients** - Update client pages
4. **Task Group 4: Projects & Invoices** - Update project and invoice pages
5. **Task Group 5: Work Entries** - Update work entries (most complex form)
6. **Task Group 6: Settings** - Update settings page
7. **Task Group 7: Visual Testing** - Set up Playwright and capture baselines

## Key Responsive Patterns Reference

| Pattern | Mobile | Desktop |
|---------|--------|---------|
| Page padding | `p-4` | `md:p-6 lg:p-8` |
| Page header | `flex-col gap-4` | `md:flex-row md:items-center md:justify-between` |
| Table/Cards | Cards visible | Table visible |
| Stats grid | `grid-cols-2` | `md:grid-cols-4` |
| Form grids | `grid-cols-1` | `md:grid-cols-2` |
| 3-col layout | `flex-col` | `lg:grid lg:grid-cols-3` |
| Buttons | `w-full` | `md:w-auto` |
| Touch targets | `min-h-11` (44px) | Standard |

## Files Summary

**New files:**
- `app/frontend/components/MobileCard.tsx`
- `app/frontend/components/PageHeader.tsx`
- `app/frontend/components/__tests__/MobileCard.test.tsx`
- `playwright.config.ts`
- `e2e/visual/mobile-screenshots.spec.ts`

**Modified files:**
- `package.json`
- `app/frontend/pages/Dashboard/Index.tsx`
- `app/frontend/pages/Dashboard/components/UnbilledByClientTable.tsx`
- `app/frontend/pages/Clients/Index.tsx`
- `app/frontend/pages/Clients/Show.tsx`
- `app/frontend/pages/Clients/Form.tsx`
- `app/frontend/pages/Projects/Index.tsx`
- `app/frontend/pages/Invoices/Index.tsx`
- `app/frontend/pages/Invoices/New.tsx`
- `app/frontend/pages/Invoices/Show.tsx`
- `app/frontend/pages/WorkEntries/Index.tsx`
- `app/frontend/pages/WorkEntries/components/QuickEntryForm.tsx`
- `app/frontend/pages/WorkEntries/components/FilterBar.tsx`
- `app/frontend/pages/WorkEntries/components/WorkEntryRow.tsx`
- `app/frontend/pages/Settings/Show.tsx`
