# Task Breakdown: i18n Localization Support

## Overview
Total Tasks: 4 Task Groups

This implementation adds internationalization (i18n) support with English and Czech language options, persistent user locale preference, and comprehensive UI translation coverage.

## Task List

### Backend Layer

#### Task Group 1: Database and Backend Setup
**Dependencies:** None

- [x] 1.0 Complete backend i18n infrastructure
  - [x] 1.1 Write 3 focused tests for locale functionality
    - Test User model locale validation (accepts 'en' and 'cs', rejects invalid values)
    - Test SettingsController#update_locale updates user locale
    - Test ApplicationController shares locale via Inertia props
  - [x] 1.2 Create migration to add locale column to users table
    - Add `locale` string column with default `'en'` and NOT NULL constraint
    - Migration should be reversible
  - [x] 1.3 Update User model with locale validation
    - Add `validates :locale, inclusion: { in: %w[en cs] }`
  - [x] 1.4 Add locale update endpoint to SettingsController
    - Add `update_locale` action that updates `Current.session.user.locale`
    - Add route: `patch '/settings/locale', to: 'settings#update_locale'`
    - Permit `:locale` in strong params
  - [x] 1.5 Update ApplicationController to share locale via Inertia
    - Add `locale` to `inertia_share` block
    - Read from `Current.session&.user&.locale` with `'en'` fallback
  - [x] 1.6 Ensure backend tests pass
    - Run ONLY the 3 tests written in 1.1
    - Verify migration runs successfully

**Acceptance Criteria:**
- The 3 tests written in 1.1 pass
- Migration adds locale column with proper default
- User model validates locale values
- Locale is shared to frontend via Inertia props

---

### Frontend Infrastructure

#### Task Group 2: i18n Configuration and Dependencies
**Dependencies:** Task Group 1

- [x] 2.0 Complete frontend i18n infrastructure
  - [x] 2.1 Write 4 focused tests for i18n functionality
    - Test i18n initializes with correct default language
    - Test `useTranslation` hook returns translated strings
    - Test `i18n.changeLanguage()` switches locale correctly
    - Test CurrencyDisplay formats according to locale (en-US vs cs-CZ)
  - [x] 2.2 Install npm dependencies
    - Add `i18next` and `react-i18next` packages
    - No additional build configuration needed
  - [x] 2.3 Create translation files
    - Create `app/frontend/locales/en.json` with all English translations
    - Create `app/frontend/locales/cs.json` with all Czech translations
    - Use namespace structure: `nav.*`, `common.*`, `pages.[resource].*`
  - [x] 2.4 Create i18n configuration module
    - Create `app/frontend/lib/i18n.ts`
    - Initialize i18next with `initReactI18next`
    - Set fallback language to `'en'`
    - Export `supportedLocales` array and `SupportedLocale` type
    - Import translation JSON files statically
  - [x] 2.5 Update application entry point
    - Import i18n config in `app/frontend/entrypoints/application.tsx`
    - Read initial locale from `initialPage.props.locale`
    - Call `i18n.changeLanguage(locale)` during setup before render
  - [x] 2.6 Create TypeScript type declarations
    - Create `app/frontend/types/i18next.d.ts`
    - Declare type options based on English translation structure
  - [x] 2.7 Update CurrencyDisplay with dynamic locale
    - Modify `app/frontend/components/CurrencyDisplay.tsx`
    - Use `useTranslation()` hook to get current locale
    - Map `en` to `en-US` and `cs` to `cs-CZ` for `toLocaleString()`
    - Update `formatCurrency` and `formatRate` utility functions
  - [x] 2.8 Ensure frontend infrastructure tests pass
    - Run ONLY the 4 tests written in 2.1
    - Verify i18n configuration loads correctly

**Acceptance Criteria:**
- The 4 tests written in 2.1 pass
- i18next and react-i18next installed
- Translation files created with proper structure
- i18n initializes correctly on app load
- CurrencyDisplay uses dynamic locale formatting

---

### UI Components and Pages

#### Task Group 3: Component Translations and Settings UI
**Dependencies:** Task Group 2

- [x] 3.0 Complete UI translations and language selector
  - [x] 3.1 Write 4 focused tests for translated components
    - Test Sidebar renders translated navigation labels
    - Test Header renders translated menu items
    - Test Settings page language selector changes locale
    - Test page component renders translated content
  - [x] 3.2 Update Sidebar component with translations
    - Add `useTranslation()` hook to `app/frontend/components/Sidebar.tsx`
    - Replace hardcoded labels: Dashboard, Log Work, Clients, Projects, Invoices, Settings, Sign out
    - Use `t('nav.dashboard')`, `t('nav.logWork')`, etc.
  - [x] 3.3 Update Header component with translations
    - Add `useTranslation()` hook to `app/frontend/components/Header.tsx`
    - Translate Settings menu item and Sign out button
  - [x] 3.4 Add language selector to Settings page
    - Add "Preferences" section to `app/frontend/pages/Settings/Show.tsx`
    - Use native `<select>` element matching existing currency selector pattern
    - Display options: "English" and "Cestina"
    - On change, submit locale update via `router.patch('/settings/locale')`
    - Call `i18n.changeLanguage()` for immediate effect
    - Style: `w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg`
  - [x] 3.5 Translate Dashboard page
    - Update `app/frontend/pages/Dashboard/Index.tsx` with translations
    - Translate stat card labels, chart titles, table headers
  - [x] 3.6 Translate Clients pages
    - Update `app/frontend/pages/Clients/Index.tsx`, `Form.tsx`, `Show.tsx`
    - Translate page titles, form labels, table headers, empty states
  - [x] 3.7 Translate Projects pages
    - Update `app/frontend/pages/Projects/Index.tsx`, `Form.tsx`, `Show.tsx`
    - Translate page titles, form labels, table headers
  - [x] 3.8 Translate Invoices pages
    - Update `app/frontend/pages/Invoices/Index.tsx`, `New.tsx`, `Show.tsx`, `Edit.tsx`
    - Translate page titles, status labels, table headers
  - [x] 3.9 Translate WorkEntries page
    - Update `app/frontend/pages/WorkEntries/Index.tsx` and components
    - Translate filter labels, table headers, form fields
  - [x] 3.10 Translate Settings page
    - Update `app/frontend/pages/Settings/Show.tsx`
    - Translate section headers, form labels, button text
  - [x] 3.11 Translate remaining pages
    - Update `app/frontend/pages/sessions/New.tsx` (login page)
    - Update `app/frontend/pages/Reports/Show.tsx` if applicable
  - [x] 3.12 Ensure UI component tests pass
    - Run ONLY the 4 tests written in 3.1
    - Verify translations render correctly

**Acceptance Criteria:**
- The 4 tests written in 3.1 pass
- All navigation items display translated text
- Language selector in Settings changes locale immediately
- All page components use translated strings

---

### Testing and Verification

#### Task Group 4: Test Review and Gap Analysis
**Dependencies:** Task Groups 1-3

- [ ] 4.0 Review existing tests and fill critical gaps
  - [ ] 4.1 Review tests from Task Groups 1-3
    - Review the 3 backend tests from Task Group 1
    - Review the 4 infrastructure tests from Task Group 2
    - Review the 4 UI tests from Task Group 3
    - Total existing tests: 11 tests
  - [ ] 4.2 Analyze test coverage gaps for i18n feature only
    - Identify critical user workflows lacking coverage
    - Focus on end-to-end locale persistence flow
    - Prioritize integration between frontend and backend
  - [ ] 4.3 Write up to 5 additional strategic tests if needed
    - Test locale persists across page navigation
    - Test locale persists after logout/login
    - Test fallback to English for missing translation keys
    - Skip edge cases unless critical
  - [ ] 4.4 Run feature-specific tests only
    - Run all i18n-related tests (backend and frontend)
    - Expected total: approximately 11-16 tests
    - Verify all critical workflows pass
  - [ ] 4.5 Manual verification checklist
    - Switch language to Czech in Settings
    - Navigate through all pages to verify translations
    - Verify currency formatting matches locale
    - Refresh page and confirm locale persists

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 11-16 tests total)
- Language switching works end-to-end
- Locale persists across navigation and page refreshes
- Currency formatting respects locale setting

---

## Execution Order

Recommended implementation sequence:
1. **Task Group 1:** Backend Layer - Database migration, model validation, controller updates
2. **Task Group 2:** Frontend Infrastructure - npm packages, i18n config, translation files, CurrencyDisplay fix
3. **Task Group 3:** UI Components - Sidebar/Header translations, Settings language selector, all page translations
4. **Task Group 4:** Testing - Gap analysis, additional tests, end-to-end verification

## Files to Create

| File | Purpose |
|------|---------|
| `db/migrate/XXXXXX_add_locale_to_users.rb` | Database migration |
| `app/frontend/lib/i18n.ts` | i18n configuration |
| `app/frontend/locales/en.json` | English translations |
| `app/frontend/locales/cs.json` | Czech translations |
| `app/frontend/types/i18next.d.ts` | TypeScript declarations |

## Files to Modify

| File | Changes |
|------|---------|
| `app/models/user.rb` | Add locale validation |
| `app/controllers/application_controller.rb` | Share locale via Inertia |
| `app/controllers/settings_controller.rb` | Handle locale update |
| `config/routes.rb` | Add locale update route |
| `app/frontend/entrypoints/application.tsx` | Initialize i18n |
| `app/frontend/components/Sidebar.tsx` | Use translations |
| `app/frontend/components/Header.tsx` | Use translations |
| `app/frontend/components/CurrencyDisplay.tsx` | Dynamic locale formatting |
| `app/frontend/pages/Settings/Show.tsx` | Add language selector |
| `app/frontend/pages/Dashboard/Index.tsx` | Translate strings |
| `app/frontend/pages/Clients/*.tsx` | Translate strings |
| `app/frontend/pages/Projects/*.tsx` | Translate strings |
| `app/frontend/pages/Invoices/*.tsx` | Translate strings |
| `app/frontend/pages/WorkEntries/*.tsx` | Translate strings |
| `app/frontend/pages/sessions/New.tsx` | Translate login page |
| `package.json` | Add i18next dependencies |

## Translation Key Structure

```json
{
  "nav": {
    "dashboard": "Dashboard",
    "logWork": "Log Work",
    "clients": "Clients",
    "projects": "Projects",
    "invoices": "Invoices",
    "settings": "Settings",
    "signOut": "Sign out"
  },
  "common": {
    "save": "Save",
    "cancel": "Cancel",
    "delete": "Delete",
    "edit": "Edit",
    "add": "Add",
    "loading": "Loading...",
    "saveChanges": "Save Changes",
    "saving": "Saving...",
    "noResults": "No results found"
  },
  "pages": {
    "settings": {
      "title": "Settings",
      "subtitle": "Configure your business details",
      "preferences": {
        "title": "Preferences",
        "language": "Language",
        "languageDescription": "Select your preferred language"
      }
    },
    "dashboard": { ... },
    "clients": { ... },
    "projects": { ... },
    "invoices": { ... },
    "workEntries": { ... }
  }
}
```
