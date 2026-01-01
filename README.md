# Invoicing

Personal time tracking and invoicing application for independent developers working with multiple clients.

## Tech Stack

- **Backend:** Rails 8.1 with Ruby 3.3
- **Frontend:** React 19 + TypeScript via Inertia.js
- **UI:** Tailwind CSS + shadcn/ui
- **Database:** SQLite3
- **PDF:** Grover (Puppeteer-based)

## Setup

```bash
bundle install
npm install
bin/rails db:prepare
```

## Development

```bash
bin/dev                    # Start Rails + Vite dev servers
```

Access the app at http://localhost:3000

## Parallel Development

Work on multiple features simultaneously with isolated environments.

### Quick Start

```bash
# Build a new feature with Claude Code
bin/build-feature "feature-name" "Description of what to build"

# Example
bin/build-feature "invoice-reminders" "Add email reminders for unpaid invoices"
```

### Commands

| Command | Description |
|---------|-------------|
| `bin/build-feature <name> <prompt>` | Create worktree and start Claude with /build |
| `bin/worktree-setup <name>` | Create isolated worktree for manual development |
| `bin/dev-feature <name>` | Run dev server with feature-specific ports (same directory) |

### How It Works

Each parallel environment gets:
- **Separate directory:** `../invoicing-<feature-name>`
- **Own git branch:** `feature/<feature-name>`
- **Isolated database:** `storage/development-<feature-name>.sqlite3`
- **Unique ports:** Rails 3001+, Vite 3137+

### Example Workflow

```bash
# Terminal 1 - main development
cd invoicing
bin/dev                     # Rails: 3000, Vite: 3036

# Terminal 2 - feature work
bin/build-feature "auth" "Add user authentication"
# Creates ../invoicing-auth and starts Claude

# Terminal 3 - another feature
bin/build-feature "reports" "Add monthly revenue reports"
# Creates ../invoicing-reports and starts Claude
```

### Managing Worktrees

```bash
# List all worktrees
git worktree list

# Remove a worktree when done
git worktree remove ../invoicing-<feature-name>

# Clean up merged branches
git branch -d feature/<feature-name>
```

## Testing

```bash
# Backend
bundle exec rspec

# Frontend
npm test              # Watch mode
npm run test:run      # Single run
npm run typecheck     # TypeScript check
```

## Build

```bash
npm run build         # Production frontend build
```

## Standalone Package

Create a self-contained macOS executable using [Tebako](https://github.com/tamatebako/tebako):

```bash
# Install dependencies (one-time)
gem install tebako
brew install create-dmg  # optional, for DMG creation

# Build the package
bin/package-macos 1.0.0
```

This creates in `dist/`:
- `invoicing-macos` - standalone executable
- `run-invoicing.command` - double-click launcher
- `Invoicing-1.0.0.dmg` - installer (if create-dmg installed)

### User Experience

Users just:
1. Download the DMG (or zip)
2. Copy files to a folder
3. Double-click `run-invoicing.command`
4. Open http://localhost:3000

Data is stored in `~/.invoicing/` and persists across updates.

### Updating

Users replace the executable files - their data stays intact. The launcher auto-runs migrations when needed.
