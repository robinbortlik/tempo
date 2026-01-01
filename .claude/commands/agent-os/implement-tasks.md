# Spec Implementation Process

Now that we have a spec and tasks list ready for implementation, we will proceed with implementation of this spec by following this multi-phase process:

PHASE 1: Parse task groups and determine execution strategy
PHASE 2: Delegate each task group to its own implementer subagent
PHASE 3: After ALL task groups have been implemented, delegate to implementation-verifier to produce the final verification report.

**CRITICAL: Never implement task groups yourself. Always delegate each task group to a separate implementer subagent.**

## Arguments

- `$ARGUMENTS` - Spec path and/or flags
  - `--chained` - When present, this command is running as part of `/build-feature` workflow. Skip interactive prompts and output machine-readable result.
  - `--spec-path <path>` - Explicit spec path to use (optional, will find most recent if not provided)

## Mode Detection

Check if `$ARGUMENTS` contains `--chained`:
- **Standalone mode**: Show full user-friendly output with confirmations and "NEXT STEP" guidance
- **Chained mode**: Proceed without confirmations and output result status

Follow each of these phases and their individual workflows IN SEQUENCE:

## Multi-Phase Process

### PHASE 1: Parse task groups and determine execution strategy

1. Read `agent-os/specs/[this-spec]/tasks.md` to identify all task groups
2. For each task group, extract:
   - Task group number and name (e.g., "Task Group 1: Data Models and Migrations")
   - Dependencies line (e.g., "**Dependencies:** None" or "**Dependencies:** Task Group 1")
   - All tasks and sub-tasks belonging to that group
3. Build a dependency map to determine execution order

**Dependency Analysis:**
- Task groups with `Dependencies: None` can start immediately
- Task groups with dependencies must wait for those dependencies to complete
- Multiple task groups with the same dependencies (or no dependencies) can run in parallel

**Check if user has specific instructions:**
- If the user specified particular task group(s) to implement, only process those
- **If running in chained mode (`--chained`)**: Proceed immediately with all task groups without asking for confirmation
- If in standalone mode and no specific instructions, ask the user:

```
I've identified the following task groups and their dependencies:

[List each task group with its dependencies]

Execution strategy:
- Parallel: [Groups that can run simultaneously]
- Sequential: [Groups that must wait for others]

Should I proceed with implementing all task groups? If not, specify which to implement.
```

### PHASE 2: Delegate each task group to its own implementer subagent

**IMPORTANT: Each task group MUST be delegated to its own separate implementer subagent. Never implement multiple task groups in a single subagent call.**

**Execution Rules:**

1. **Independent task groups (no unmet dependencies):** Launch implementer subagents in parallel using multiple Task tool calls in a single message with `run_in_background: true`

2. **Dependent task groups:** Wait for dependencies to complete before launching. Use `TaskOutput` to monitor background agents and determine when to proceed.

**For each task group, spawn an implementer subagent with:**

```
Implement Task Group [N]: [Name]

Spec path: agent-os/specs/[this-spec]/spec.md
Requirements path: agent-os/specs/[this-spec]/planning/requirements.md
Visuals path: agent-os/specs/[this-spec]/planning/visuals (if exists)

Task Group to implement:
[Copy the ENTIRE task group section from tasks.md, including:]
- The "#### Task Group N: Name" header
- The "**Dependencies:**" line
- All "- [ ]" tasks and their sub-items
- The "**Acceptance Criteria:**" section

Instructions:
1. Implement ONLY this task group - do not work on other groups
2. Follow the spec.md and requirements.md closely
3. Update tasks.md to mark completed tasks with "- [x]"
4. Commit the completed task group with a descriptive message
```

**Orchestration Flow:**

```
Example with 6 task groups:
- Group 1: Dependencies: None         → Start immediately (background)
- Group 2: Dependencies: Group 1      → Wait for Group 1, then start
- Group 3: Dependencies: Group 2      → Wait for Group 2, then start
- Group 4: Dependencies: Group 3      → Wait for Group 3, then start
- Group 5: Dependencies: Group 4      → Wait for Group 4, then start
- Group 6: Dependencies: Groups 1-5   → Wait for all, then start

If groups had different dependencies:
- Groups 1, 2: Dependencies: None     → Start both in parallel (background)
- Group 3: Dependencies: Group 1      → Start after Group 1 completes
- Group 4: Dependencies: Group 2      → Start after Group 2 completes
- Groups 3 and 4 can run in parallel since they have different dependencies
```

**Monitoring Progress:**

1. After launching background agents, use `TaskOutput` with `block: true` to wait for completion
2. When a task group completes, check which dependent groups can now start
3. Continue until all task groups are complete
4. Track any failures and report them to the user

### PHASE 3: Produce the final verification report

IF ALL task groups in tasks.md are marked complete with `- [x]`, then proceed with this step. Otherwise, report incomplete groups to the user.

Delegate to the **implementation-verifier** subagent:

```
Verify implementation for spec: agent-os/specs/[this-spec]

Instructions:
1. Run all final verifications according to your built-in workflow
2. Produce the final verification report in agent-os/specs/[this-spec]/verification/final-verification.md
```

## Summary

| Phase | Action |
|-------|--------|
| 1 | Parse tasks.md, extract groups and dependencies, determine parallel vs sequential execution |
| 2 | Spawn separate implementer subagent for EACH task group, respecting dependencies |
| 3 | After all complete, run implementation-verifier for final report |

**Key Principle:** This command is an ORCHESTRATOR. It delegates work to implementer subagents and coordinates their execution. It never implements code itself.

## Final Output

After all phases complete:

**If running in chained mode (`--chained` in $ARGUMENTS):**

If implementation succeeded:
```
IMPLEMENT_COMPLETE::[spec-path]::[number of task groups completed]
```

If implementation had failures:
```
IMPLEMENT_FAILED::[spec-path]::[comma-separated list of failed task groups]
```

**If running in standalone mode:**

```
Implementation Complete!

✅ All [X] task groups implemented
✅ Verification report: [spec-path]/verification/final-verification.md

NEXT STEP 👉 Commit and push your changes, then create a PR.
```
