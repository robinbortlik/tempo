# Process for Orchestrating a Spec's Implementation

Now that we have a spec and tasks list ready for implementation, we will proceed with orchestrating implementation of each task group by a dedicated agent using the following MULTI-PHASE process.

**CRITICAL: Never implement task groups yourself. Always delegate each task group to a separate subagent.**

Follow each of these phases and their individual workflows IN SEQUENCE:

## Multi-Phase Process

### FIRST: Get tasks.md for this spec

IF you already know which spec we're working on and IF that spec folder has a `tasks.md` file, then use that and skip to the NEXT phase.

IF you don't already know which spec we're working on and IF that spec folder doesn't yet have a `tasks.md` THEN output the following request to the user:

```
Please point me to a spec's `tasks.md` that you want to orchestrate implementation for.

If you don't have one yet, then run any of these commands first:
/shape-spec
/write-spec
/create-tasks
```

### NEXT: Create orchestration.yml to serve as a roadmap for orchestration of task groups

In this spec's folder, create this file: `agent-os/specs/[this-spec]/orchestration.yml`.

1. Parse `tasks.md` to extract each task group with:
   - Task group number and name
   - Dependencies (from the `**Dependencies:**` line)

2. Populate `orchestration.yml` with the names AND dependencies of each task group:

```yaml
task_groups:
  - name: [task-group-name]
    number: 1
    dependencies: []  # or list of group numbers, e.g., [1, 2]
  - name: [task-group-name]
    number: 2
    dependencies: [1]
  - name: [task-group-name]
    number: 3
    dependencies: [2]
  # Repeat for each task group found in tasks.md
```

### NEXT: Ask user to assign subagents to each task group

Next we must determine which subagents should be assigned to which task groups.  Ask the user to provide this info using the following request to user and WAIT for user's response:

```
Please specify the name of each subagent to be assigned to each task group:

1. [task-group-name]
2. [task-group-name]
3. [task-group-name]
[repeat for each task-group you've added to orchestration.yml]

Simply respond with the subagent names and corresponding task group number and I'll update orchestration.yml accordingly.
```

Using the user's responses, update `orchestration.yml` to specify those subagent names.  `orchestration.yml` should end up looking like this:

```yaml
task_groups:
  - name: [task-group-name]
    claude_code_subagent: [subagent-name]
  - name: [task-group-name]
    claude_code_subagent: [subagent-name]
  - name: [task-group-name]
    claude_code_subagent: [subagent-name]
  # Repeat for each task group found in tasks.md
```

For example, after this step, the `orchestration.yml` file might look like this (exact names will vary):

```yaml
task_groups:
  - name: authentication-system
    claude_code_subagent: backend-specialist
  - name: user-dashboard
    claude_code_subagent: frontend-specialist
  - name: api-endpoints
    claude_code_subagent: backend-specialist
```

### NEXT: Ask user to assign standards to each task group

Next we must determine which standards should guide the implementation of each task group.  Ask the user to provide this info using the following request to user and WAIT for user's response:

```
Please specify the standard(s) that should be used to guide the implementation of each task group:

1. [task-group-name]
2. [task-group-name]
3. [task-group-name]
[repeat for each task-group you've added to orchestration.yml]

For each task group number, you can specify any combination of the following:

"all" to include all of your standards
"global/*" to include all of the files inside of standards/global
"frontend/css.md" to include the css.md standard file
"none" to include no standards for this task group.
```

Using the user's responses, update `orchestration.yml` to specify those standards for each task group.  `orchestration.yml` should end up having AT LEAST the following information added to it:

```yaml
task_groups:
  - name: [task-group-name]
    standards:
      - [users' 1st response for this task group]
      - [users' 2nd response for this task group]
      - [users' 3rd response for this task group]
      # Repeat for all standards that the user specified for this task group
  - name: [task-group-name]
    standards:
      - [users' 1st response for this task group]
      - [users' 2nd response for this task group]
      # Repeat for all standards that the user specified for this task group
  # Repeat for each task group found in tasks.md
```

For example, after this step, the `orchestration.yml` file might look like this (exact names will vary):

```yaml
task_groups:
  - name: authentication-system
    standards:
      - all
  - name: user-dashboard
    standards:
      - global/*
      - frontend/components.md
      - frontend/css.md
  - name: task-group-with-no-standards
  - name: api-endpoints
    standards:
      - backend/*
      - global/error-handling.md
```

Note: If the `use_claude_code_subagents` flag is enabled, the final `orchestration.yml` would include BOTH `claude_code_subagent` assignments AND `standards` for each task group.

### NEXT: Determine execution strategy based on dependencies

Before delegating, analyze the dependency graph to determine execution order:

**Execution Rules:**

1. **Independent task groups (dependencies: [] or all dependencies completed):** Launch subagents in parallel using multiple Task tool calls in a single message with `run_in_background: true`

2. **Dependent task groups:** Wait for dependencies to complete before launching. Use `TaskOutput` to monitor background agents and determine when to proceed.

**Present execution strategy to user:**

```
Based on the dependency analysis, here's the execution strategy:

Parallel Execution Groups:
- Wave 1: [Groups with no dependencies - can start immediately]
- Wave 2: [Groups that depend only on Wave 1]
- Wave 3: [Groups that depend on Wave 1 or 2]
... and so on

Sequential chains:
- Group X → Group Y → Group Z (must run in order)

Proceed with this execution strategy? [Y/n]
```

### NEXT: Delegate task groups implementations to assigned subagents

**IMPORTANT: Each task group MUST be delegated to its own separate subagent. Never implement multiple task groups in a single subagent call.**

**Orchestration Flow:**

1. Start all task groups with no unmet dependencies (Wave 1) in parallel using `run_in_background: true`
2. Use `TaskOutput` with `block: true` to wait for Wave 1 completions
3. When a task group completes, check which dependent groups can now start
4. Launch newly-unblocked groups (next wave) in parallel
5. Continue until all task groups are complete
6. Track any failures and report them to the user

For each delegation, provide the subagent with:
- The task group (including the parent task and all sub-tasks)
- The spec file: `agent-os/specs/[this-spec]/spec.md`
- Instruct subagent to:
  - Perform their implementation
  - Check off the task and sub-task(s) in `agent-os/specs/[this-spec]/tasks.md`
  - Commit the completed task group with a descriptive message

In addition to the above items, also instruct the subagent to closely adhere to the user's standards & preferences as specified in the following files.  To build the list of file references to give to the subagent, follow these instructions:

#### Compile Implementation Standards

Use the following logic to compile a list of file references to standards that should guide implementation:

##### Steps to Compile Standards List

1. Find the current task group in `orchestration.yml`
2. Check the list of `standards` specified for this task group in `orchestration.yml`
3. Compile the list of file references to those standards, one file reference per line, using this logic for determining which files to include:
   a. If the value for `standards` is simply `all`, then include every single file, folder, sub-folder and files within sub-folders in your list of files.
   b. If the item under standards ends with "*" then it means that all files within this folder or sub-folder should be included. For example, `frontend/*` means include all files and sub-folders and their files located inside of `agent-os/standards/frontend/`.
   c. If a file ends in `.md` then it means this is one specific file you must include in your list of files. For example `backend/api.md` means you must include the file located at `agent-os/standards/backend/api.md`.
   d. De-duplicate files in your list of file references.

##### Output Format

The compiled list of standards should look something like this, where each file reference is on its own line and begins with `@`. The exact list of files will vary:

```
@agent-os/standards/global/coding-style.md
@agent-os/standards/global/conventions.md
@agent-os/standards/global/tech-stack.md
@agent-os/standards/backend/controllers.md
@agent-os/standards/backend/services.md
@agent-os/standards/backend/serializers.md
@agent-os/standards/frontend/components.md
@agent-os/standards/frontend/css.md
```


Provide all of the above to the subagent when delegating tasks for it to implement.

### FINAL: Verification after all task groups complete

IF ALL task groups in tasks.md are marked complete with `- [x]`, delegate to the **implementation-verifier** subagent:

```
Verify implementation for spec: agent-os/specs/[this-spec]

Instructions:
1. Run all final verifications according to your built-in workflow
2. Produce the final verification report in agent-os/specs/[this-spec]/verification/final-verification.md
```

## Summary

| Phase | Action |
|-------|--------|
| 1 | Get tasks.md and create orchestration.yml with task groups and dependencies |
| 2 | User assigns subagents to each task group |
| 3 | User assigns standards to each task group |
| 4 | Determine execution strategy (parallel waves based on dependencies) |
| 5 | Delegate each task group to its own subagent, respecting dependencies |
| 6 | Run implementation-verifier for final report |

**Key Principle:** This command is an ORCHESTRATOR. It delegates work to subagents and coordinates their execution based on dependencies. It never implements code itself.
