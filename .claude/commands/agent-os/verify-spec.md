# Spec Verification Process

Verify that the specification and tasks accurately reflect requirements before implementation.

## Arguments

- `$ARGUMENTS` - Path to spec folder and/or flags
  - `--chained` - When present, this command is running as part of `/build-feature` workflow. Skip "NEXT STEP" messaging and output machine-readable result.
  - `--spec-path <path>` - Explicit spec path to use (optional, will find most recent if not provided)

## Mode Detection

Check if `$ARGUMENTS` contains `--chained`:
- **Standalone mode**: Show full user-friendly output with "NEXT STEP" guidance
- **Chained mode**: Output result status with PASSED/FAILED indicator

## Process

### Step 1: Find the spec to verify

If `$ARGUMENTS` provides a spec path, use that.

Otherwise, find the most recent spec:

```bash
ls -td agent-os/specs/*/ 2>/dev/null | head -1
```

If no spec found, OUTPUT:
```
No spec folder found. Please run /shape-spec first to create a specification.
```

### Step 2: Verify required files exist

Check that the spec has the necessary files:

```bash
SPEC_PATH="[spec-folder-path]"

# Check for required files
ls -la "$SPEC_PATH/planning/requirements.md" 2>/dev/null
ls -la "$SPEC_PATH/spec.md" 2>/dev/null
ls -la "$SPEC_PATH/tasks.md" 2>/dev/null
```

If files are missing, OUTPUT:
```
Missing required files for verification:

- requirements.md: [Found/Missing]
- spec.md: [Found/Missing]
- tasks.md: [Found/Missing]

Please run the following commands first:
- /shape-spec (if requirements.md is missing)
- /write-spec (if spec.md is missing)
- /create-tasks (if tasks.md is missing)
```

### Step 3: Run verification

Use the **spec-verifier** subagent to validate the specification.

Provide the spec-verifier with:
- The spec folder path
- The content of `planning/requirements.md`
- Any visual assets in `planning/visuals/`

The spec-verifier will:
1. Verify requirements accuracy
2. Check structural integrity
3. Analyze visual alignment (if visuals exist)
4. Validate reusability opportunities
5. Verify test writing limits
6. Create verification report

### Step 4: Report results

After verification completes:

**If running in chained mode (`--chained` in $ARGUMENTS):**

If verification PASSED:
```
VERIFY_SPEC_PASSED::[spec-path]
```

If verification found CRITICAL issues:
```
VERIFY_SPEC_FAILED::[spec-path]::[comma-separated list of critical issues]
```

**If running in standalone mode:**

If verification PASSED:
```
Spec Verification Complete!

✅ All checks passed
✅ Requirements accurately captured
✅ Specification aligned with requirements
✅ Tasks properly scoped

Verification report: [spec-path]/verification/spec-verification.md

NEXT STEP 👉 Run `/implement-tasks` to start implementation.
```

If verification found ISSUES:
```
Spec Verification Complete - Issues Found

⚠️ Verification found issues that should be addressed:

Critical Issues:
[List critical issues from verification report]

Minor Issues:
[List minor issues from verification report]

Verification report: [spec-path]/verification/spec-verification.md

Recommendations:
1. Review the verification report
2. Update spec.md and/or tasks.md to address issues
3. Run `/verify-spec` again before implementation
```

## Notes

- This command can be run independently or as part of `/build-feature`
- Verification helps catch issues before implementation begins
- The verification report is saved for documentation purposes
