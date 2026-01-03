# Update standards

IMPORTANT: Think ultra hard.

Here is a documentation for AgentOS standards: `https://buildermethods.com/agent-os/standards` . Your goal is to revisit current standards defined in agent-os/standards and generate new most relevant standards based on current project setup.
Remove those standards which are irrelevant for this project.

Before you start, read the `Gemfile` and get a context of the libraries used in this project and follow theirs best practices.

## Final Step: Verify and Fix Standards References

After generating/updating standards files, you MUST verify and fix all references to standards in the agent-os agents and commands.

### Step 1: Get the list of actual standards files

```bash
find agent-os/standards -name "*.md" -type f | sort
```

### Step 2: Find all standards references in agents and commands

```bash
grep -r "@agent-os/standards/" .claude/agents/ .claude/commands/ 2>/dev/null | grep -v "^Binary"
```

### Step 3: Compare and fix broken references

For each file that references standards (files in `.claude/agents/` and `.claude/commands/`):

1. **Identify broken references**: Compare the `@agent-os/standards/...` references against actual files from Step 1
2. **Remove references to non-existent files**: Delete any `@agent-os/standards/...` line that points to a file that doesn't exist
3. **Add missing references**: If a standards file exists but is not referenced, consider adding it if relevant to that agent's role:
   - Backend agents should reference: `backend/*.md`
   - Frontend agents should reference: `frontend/*.md`
   - All agents should reference: `global/*.md`, `testing/*.md`

### Step 4: Report changes

Output a summary of:
- Standards files that were referenced but don't exist (removed)
- Standards files that exist but weren't referenced (added if relevant)
- Files that were updated

This ensures all agent-os agents and commands reference only valid standards files.
