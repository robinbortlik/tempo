# Build Feature - Complete End-to-End Workflow

Orchestrate the complete feature development workflow from idea to deployed code.

This command automates the entire AgentOS workflow:
1. Shape spec (gather requirements)
2. Write spec
3. Create tasks
4. Verify spec
5. Implement all tasks
6. Verify implementation
7. Commit and push to GitHub

## Arguments

- `$ARGUMENTS` - Feature description or branch name (optional)

## Multi-Phase Process

Follow each phase IN SEQUENCE. After each phase, check for errors and handle accordingly.

---

### PHASE 0: Initialize and Determine Context

First, determine the current state and what needs to happen:

#### Step 0.1: Check for existing spec in progress

```bash
# Check for recent specs (last 7 days)
find agent-os/specs -maxdepth 1 -type d -name "$(date +%Y-%m)*" 2>/dev/null | head -5
```

If recent specs exist, ask the user:

```
I found existing spec(s) in progress:
[list specs found]

Would you like to:
1. Continue with an existing spec (specify which one)
2. Start a new feature from scratch

Please respond with your choice.
```

Wait for user response before proceeding.

---

### PHASE 1: Shape Specification

Use the **spec-initializer** subagent to initialize a new spec folder.

Provide the spec-initializer with:
- The feature description from `$ARGUMENTS` or from user's earlier response

After spec-initializer completes, immediately use the **spec-shaper** subagent:

Provide the spec-shaper with:
- The spec folder path from spec-initializer

The spec-shaper uses **AskUserQuestion tool** to gather requirements interactively. Wait for all question rounds to complete.

After spec shaping completes, OUTPUT:
```
Phase 1 Complete: Spec Shaping

✅ Spec folder created: [spec-path]
✅ Requirements gathered and documented

Proceeding to Phase 2: Write Specification...
```

---

### PHASE 2: Write Specification

Use the **spec-writer** subagent to create the specification document.

Provide the spec-writer with:
- The spec folder path
- The requirements from `planning/requirements.md`
- Any visual assets in `planning/visuals/`

After spec-writer completes, OUTPUT:
```
Phase 2 Complete: Specification Written

✅ spec.md created: [spec-path]/spec.md

Proceeding to Phase 3: Create Tasks...
```

---

### PHASE 3: Create Task List

Use the **tasks-list-creator** subagent to break down the spec into actionable tasks.

Provide the tasks-list-creator with:
- `agent-os/specs/[this-spec]/spec.md`
- `agent-os/specs/[this-spec]/planning/requirements.md`
- `agent-os/specs/[this-spec]/planning/visuals/` (if present)

After tasks-list-creator completes, OUTPUT:
```
Phase 3 Complete: Tasks Created

✅ tasks.md created: [spec-path]/tasks.md

Proceeding to Phase 4: Verify Specification...
```

---

### PHASE 4: Verify Specification

Use the **spec-verifier** subagent to validate the spec and tasks against requirements.

Provide the spec-verifier with:
- The spec folder path
- The questions asked during requirements gathering
- The user's responses

After spec-verifier completes, check the verification report at `[spec-path]/verification/spec-verification.md`.

**If verification PASSED:**
```
Phase 4 Complete: Specification Verified

✅ All checks passed
✅ Verification report: [spec-path]/verification/spec-verification.md

Proceeding to Phase 5: Implementation...
```

**If verification found CRITICAL ISSUES:**
```
Phase 4: Specification Verification Found Issues

⚠️ Critical issues found in specification:
[List critical issues from verification report]

Would you like to:
1. Fix the issues and re-verify (recommended)
2. Proceed with implementation anyway
3. Stop and review manually

Please respond with your choice.
```

Wait for user response. If user chooses to fix, provide guidance on what to update, then re-run spec-verifier.

---

### PHASE 5: Implement All Tasks

Before starting implementation, create a checkpoint commit:

```bash
git add agent-os/specs/
git commit -m "$(cat <<'EOF'
feat: Add specification for [feature-name]

- Created spec folder with requirements
- Generated spec.md with full specification
- Created tasks.md with implementation breakdown
- Verified specification against requirements

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

Now delegate to the **implementer** subagent to implement ALL task groups:

Provide the implementer with:
- ALL task groups from `agent-os/specs/[this-spec]/tasks.md`
- The spec file: `agent-os/specs/[this-spec]/spec.md`
- The requirements: `agent-os/specs/[this-spec]/planning/requirements.md`
- The visuals (if any): `agent-os/specs/[this-spec]/planning/visuals`

Instruct the implementer to:
1. Implement each task group sequentially
2. Mark completed tasks with `- [x]` in tasks.md
3. Commit after each completed task group with a descriptive message
4. Continue until ALL task groups are complete

After ALL task groups are implemented, OUTPUT:
```
Phase 5 Complete: Implementation Finished

✅ All task groups implemented
✅ Changes committed

Proceeding to Phase 6: Verify Implementation...
```

---

### PHASE 6: Verify Implementation

Use the **implementation-verifier** subagent to verify the complete implementation.

Provide the implementation-verifier with:
- The spec path: `agent-os/specs/[this-spec]`

Instruct the implementation-verifier to:
1. Verify all tasks are marked complete
2. Update the product roadmap if applicable
3. Run the entire test suite
4. Create the final verification report at `agent-os/specs/[this-spec]/verifications/final-verification.md`

After verification completes, OUTPUT:
```
Phase 6 Complete: Implementation Verified

✅ All tasks verified complete
✅ Test suite results: [X passing, Y failing]
✅ Final verification report: [spec-path]/verifications/final-verification.md

Proceeding to Phase 7: Push to GitHub...
```

---

### PHASE 7: Push to GitHub

First, ensure all changes are committed:

```bash
git add -A
git status
```

If there are uncommitted changes, commit them:

```bash
git commit -m "$(cat <<'EOF'
feat: Complete [feature-name] implementation

- All tasks implemented and verified
- Tests passing: [X/Y]
- See agent-os/specs/[spec-folder] for full documentation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

Push to remote:

```bash
git push -u origin HEAD
```

Ask user about PR creation:

```
All changes pushed to GitHub!

Would you like me to create a Pull Request?

1. Yes, create PR with auto-generated description
2. No, I'll create it manually

Please respond with your choice.
```

**If user wants PR:**

```bash
gh pr create --title "[Feature Name]" --body "$(cat <<'EOF'
## Summary

[Brief description based on spec.md]

## Changes

- [List main changes from tasks.md]
EOF
)"
```

---

### PHASE 8: Final Summary

OUTPUT the complete summary:

```
🎉 Feature Build Complete!

═══════════════════════════════════════════════════════
📋 SPECIFICATION
═══════════════════════════════════════════════════════
   Spec Folder: agent-os/specs/[spec-folder]
   Requirements: ✅ Gathered and documented
   Specification: ✅ Written and verified
   Tasks: ✅ Created and completed

═══════════════════════════════════════════════════════
🔨 IMPLEMENTATION
═══════════════════════════════════════════════════════
   Task Groups: [X] completed
   Commits: [Y] commits made
   Tests: [passing]/[total] passing

═══════════════════════════════════════════════════════
🚀 DEPLOYMENT
═══════════════════════════════════════════════════════
   Branch: [branch-name]
   Pushed: ✅ origin/[branch-name]
   PR: [PR-URL or "Not created"]

═══════════════════════════════════════════════════════

Next steps:
- Review the PR and request reviews
- Merge when approved
```

---

## Error Handling

Throughout the workflow, if any phase fails:

1. **Subagent failure**: Report the error and ask user how to proceed
2. **Git errors**: Show the error and suggest resolution
3. **Test failures**: Document in verification report, ask user if blocking
4. **User cancellation**: Save progress and provide resume instructions

## Resume Capability

If the workflow is interrupted, running `/build-feature` again will:
1. Detect the existing spec folder
2. Determine which phase was last completed
3. Offer to resume from that point

## Notes

- This command orchestrates multiple subagents sequentially
- User interaction is required during spec shaping (Phase 2)
- Commits are made at key checkpoints for safety
- The workflow can be resumed if interrupted
- All documentation is preserved in the spec folder
