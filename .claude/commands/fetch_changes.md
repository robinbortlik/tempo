# Fetch Changes

Load all changes made in the current branch into context.

## Arguments

- `$ARGUMENTS` - Optional base branch to compare against (defaults to `master`)

## Process

1. Determine the current branch: `git branch --show-current`
2. Use `$ARGUMENTS` as base branch if provided, otherwise default to `master`
3. Get the full diff: `git diff <base-branch>...HEAD`
4. Reply with just "DONE" when finished reading the changes
