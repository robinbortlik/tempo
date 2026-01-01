# Build Feature - Complete End-to-End Workflow

Orchestrate the complete feature development workflow from idea to deployed code.

This command chains together the individual AgentOS commands:
1. `/agent-os:shape-spec` - Gather requirements
2. `/agent-os:write-spec` - Write specification
3. `/agent-os:create-tasks` - Create task list
4. `/agent-os:verify-spec` - Verify specification
5. `/agent-os:implement-tasks` - Implement all tasks
6. `/agent-os:verify-implementation` - Verify implementation
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

#### Step 0.2: Determine starting point

Based on user response or existing spec state, determine which phase to start from:

- No spec exists → Start at PHASE 1
- Spec has `planning/requirements.md` but no `spec.md` → Start at PHASE 2
- Spec has `spec.md` but no `tasks.md` → Start at PHASE 3
- Spec has `tasks.md` but not verified → Start at PHASE 4
- Spec verified but not implemented → Start at PHASE 5
- Spec implemented but not verified → Start at PHASE 6
- Implementation verified → Start at PHASE 7

Store the spec path for subsequent phases: `SPEC_PATH=[spec-folder-path]`

---

### PHASE 1: Shape Specification

**Invoke the shape-spec command:**

```
/agent-os:shape-spec --chained $ARGUMENTS
```

The command will:
- Initialize a new spec folder
- Run interactive requirements gathering via AskUserQuestion
- Output `SHAPE_COMPLETE::[spec-path]` when done

**Capture the spec path** from the output for subsequent phases.

After shape-spec completes, OUTPUT:
```
Phase 1 Complete: Spec Shaping

✅ Spec folder created: [spec-path]
✅ Requirements gathered and documented

Proceeding to Phase 2: Write Specification...
```

---

### PHASE 2: Write Specification

**Invoke the write-spec command:**

```
/agent-os:write-spec --chained --spec-path [SPEC_PATH]
```

The command will:
- Create `spec.md` from requirements
- Output `SPEC_COMPLETE::[spec-path]` when done

After write-spec completes, OUTPUT:
```
Phase 2 Complete: Specification Written

✅ spec.md created: [spec-path]/spec.md

Proceeding to Phase 3: Create Tasks...
```

---

### PHASE 3: Create Task List

**Invoke the create-tasks command:**

```
/agent-os:create-tasks --chained --spec-path [SPEC_PATH]
```

The command will:
- Create `tasks.md` with task groups and dependencies
- Output `TASKS_COMPLETE::[spec-path]` when done

After create-tasks completes, OUTPUT:
```
Phase 3 Complete: Tasks Created

✅ tasks.md created: [spec-path]/tasks.md

Proceeding to Phase 4: Verify Specification...
```

---

### PHASE 4: Verify Specification

**Invoke the verify-spec command:**

```
/agent-os:verify-spec --chained --spec-path [SPEC_PATH]
```

The command will output one of:
- `VERIFY_SPEC_PASSED::[spec-path]`
- `VERIFY_SPEC_FAILED::[spec-path]::[issues]`

**If verification PASSED:**
```
Phase 4 Complete: Specification Verified

✅ All checks passed
✅ Verification report: [spec-path]/verification/spec-verification.md

Proceeding to Phase 5: Implementation...
```

**If verification FAILED:**
```
Phase 4: Specification Verification Found Issues

⚠️ Critical issues found in specification:
[List critical issues from output]

Would you like to:
1. Fix the issues and re-verify (recommended)
2. Proceed with implementation anyway
3. Stop and review manually

Please respond with your choice.
```

Wait for user response. If user chooses to fix, provide guidance on what to update, then re-run `/agent-os:verify-spec --chained`.

---

### PHASE 5: Checkpoint Commit and Implementation

Before starting implementation, create a checkpoint commit:

```bash
git add agent-os/specs/
git commit -m "$(cat <<'EOF'
feat: Add specification for [feature-name]

- Created spec folder with requirements
- Generated spec.md with full specification
- Created tasks.md with implementation breakdown
- Verified specification against requirements
EOF
)"
```

**Invoke the implement-tasks command:**

```
/agent-os:implement-tasks --chained --spec-path [SPEC_PATH]
```

The command will:
- Parse task groups and dependencies
- Delegate each task group to implementer subagents
- Output `IMPLEMENT_COMPLETE::[spec-path]::[count]` or `IMPLEMENT_FAILED::[spec-path]::[issues]`

After implement-tasks completes, OUTPUT:
```
Phase 5 Complete: Implementation Finished

✅ All task groups implemented
✅ Changes committed

Proceeding to Phase 6: Verify Implementation...
```

---

### PHASE 6: Verify Implementation

**Invoke the verify-implementation command:**

```
/agent-os:verify-implementation --chained --spec-path [SPEC_PATH]
```

The command will output one of:
- `VERIFY_IMPL_PASSED::[spec-path]::[passing]::[failing]`
- `VERIFY_IMPL_FAILED::[spec-path]::[issues]`

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

1. **Command failure**: Report the error and ask user how to proceed
2. **Git errors**: Show the error and suggest resolution
3. **Test failures**: Document in verification report, ask user if blocking
4. **User cancellation**: Save progress and provide resume instructions

## Resume Capability

If the workflow is interrupted, running `/build-feature` again will:
1. Detect the existing spec folder
2. Determine which phase was last completed (Step 0.2)
3. Offer to resume from that point

## Notes

- This command orchestrates the individual AgentOS commands
- User interaction is required during spec shaping (Phase 1)
- Commits are made at key checkpoints for safety
- The workflow can be resumed if interrupted
- All documentation is preserved in the spec folder
