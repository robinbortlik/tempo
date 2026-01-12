# Codebase Concerns

**Analysis Date:** 2026-01-12

## Tech Debt

**Large Frontend Components:**
- Issue: Several page components exceed 500 lines, making them hard to maintain
- Files:
  - `app/frontend/pages/Invoices/Show.tsx` (827 lines)
  - `app/frontend/pages/Invoices/Edit.tsx` (582 lines)
  - `app/frontend/pages/Clients/Show.tsx` (580 lines)
  - `app/frontend/pages/WorkEntries/components/WorkEntryRow.tsx` (531 lines)
  - `app/frontend/pages/Settings/Show.tsx` (497 lines)
- Why: Rapid feature development during initial build
- Impact: Difficult to test, maintain, and understand
- Fix approach: Extract sub-components (line item display, status management, etc.)

**Missing .env.example:**
- Issue: No template file documenting required environment variables
- Files: Project root missing `.env.example`
- Why: Single-developer project, credentials managed locally
- Impact: Onboarding difficulty, credential documentation gap
- Fix approach: Create `.env.example` with all required variables (without values)

## Known Bugs

**None identified during analysis**

The codebase appears stable with good validation coverage.

## Security Considerations

**Share Token in URL:**
- Risk: Public share tokens exposed in URLs could be logged, cached, or shared unintentionally
- Files: `app/controllers/reports_controller.rb` (line 41)
- Current mitigation: Tokens are UUIDs, `sharing_enabled` flag required
- Recommendations: Consider rate limiting, token rotation, or POST-based token validation

**Unvalidated Date Parsing:**
- Risk: Malformed dates could raise `ArgumentError` if not handled
- Files: `app/services/invoice_builder.rb` (lines 5-11)
- Current mitigation: None - relies on valid input
- Recommendations: Add explicit date validation with user-friendly error messages

## Performance Bottlenecks

**N+1 Query in Line Item Destruction:**
- Problem: Individual updates when destroying line items
- Files: `app/controllers/invoice_line_items_controller.rb` (lines 28-30)
- Measurement: Not profiled, but iterates per work entry
- Cause: `entries.each { |e| e.update!(...) }` pattern
- Improvement path: Use `update_all` for bulk operations

**Projects Query Missing Eager Loading:**
- Problem: Potential N+1 when loading projects with clients
- Files: `app/controllers/projects_controller.rb` (line 5)
- Measurement: Not profiled
- Cause: Missing `.includes(:client)` on query
- Improvement path: Add eager loading before serialization

## Fragile Areas

**PDF Generation Pipeline:**
- Files: `app/services/invoice_pdf_service.rb`, `app/controllers/invoices_controller.rb`
- Why fragile: Depends on Puppeteer/Chromium availability, memory limits
- Common failures: Chrome crashes, timeout on large invoices
- Safe modification: Test PDF generation after template changes
- Test coverage: Has service spec but no integration test for full flow

**Invoice Finalization:**
- Files: `app/controllers/invoices_controller.rb` (lines 98-110)
- Why fragile: Multiple operations in transaction (finalize, update entries)
- Common failures: Race conditions if same invoice finalized concurrently
- Safe modification: Check status atomically, use pessimistic locking
- Test coverage: Request spec exists but doesn't test concurrent access

## Scaling Limits

**SQLite Database:**
- Current capacity: Suitable for single-user app with moderate data
- Limit: Concurrent writes (SQLite locks entire database)
- Symptoms at limit: Slow responses under concurrent load
- Scaling path: Migrate to PostgreSQL if multi-user needed

**Single Server Deployment:**
- Current capacity: Single Kamal-deployed Docker container
- Limit: Vertical scaling only (larger server)
- Symptoms at limit: Resource exhaustion
- Scaling path: Not needed for single-user invoicing app

## Dependencies at Risk

**No critical dependencies at risk identified**

All major dependencies (Rails 8, React 19, Vite) are actively maintained.

## Missing Critical Features

**No missing critical features identified**

The application covers core invoicing functionality.

## Test Coverage Gaps

**Frontend Page Components:**
- What's not tested: Large page components lack dedicated tests
- Files missing tests:
  - `app/frontend/pages/Invoices/Show.tsx`
  - `app/frontend/pages/Invoices/Edit.tsx`
  - `app/frontend/pages/Clients/Show.tsx`
  - `app/frontend/pages/Settings/Show.tsx`
- Risk: UI regressions undetected
- Priority: Medium
- Difficulty to test: Requires mocking Inertia page props

**PDF Generation End-to-End:**
- What's not tested: Full PDF generation flow with Puppeteer
- Risk: Template changes could break PDF output silently
- Priority: Medium
- Difficulty to test: Requires Chromium in test environment

**Error Handling in Services:**
- What's not tested: Error scenarios in some services
- Risk: Unhandled exceptions in edge cases
- Priority: Low
- Difficulty to test: Requires simulating failure conditions

---

*Concerns audit: 2026-01-12*
*Update as issues are fixed or new ones discovered*
