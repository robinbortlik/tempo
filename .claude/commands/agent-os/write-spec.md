# Spec Writing Process

You are creating a comprehensive specification for a new feature.

## Arguments

- `$ARGUMENTS` - Spec path and/or flags
  - `--chained` - When present, this command is running as part of `/build-feature` workflow. Skip "NEXT STEP" messaging and output machine-readable result.
  - `--spec-path <path>` - Explicit spec path to use (optional, will find most recent if not provided)

## Mode Detection

Check if `$ARGUMENTS` contains `--chained`:
- **Standalone mode**: Show full user-friendly output with "NEXT STEP" guidance
- **Chained mode**: Output only the result status for the next command in the workflow

## Process

Use the **spec-writer** subagent to create the specification document for this spec:

Provide the spec-writer with:
- The spec folder path (find the current one or the most recent in `agent-os/specs/*/`)
- The requirements from `planning/requirements.md`
- Any visual assets in `planning/visuals/`

The spec-writer will create `spec.md` inside the spec folder.

Once the spec-writer has created `spec.md`:

**If running in chained mode (`--chained` in $ARGUMENTS):**

```
SPEC_COMPLETE::[spec-path]
```

**If running in standalone mode:**

```
Your spec.md is ready!

✅ Spec document created: `[spec-path]`

NEXT STEP 👉 Run `/create-tasks` to generate your tasks list for this spec.
```
