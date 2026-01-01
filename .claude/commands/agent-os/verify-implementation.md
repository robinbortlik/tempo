# Implementation Verification Process

Verify that the implementation is complete, tests pass, and documentation is updated.

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

### Step 2: Verify implementation prerequisites

Check that implementation has been done:

```bash
SPEC_PATH="[spec-folder-path]"

# Check tasks.md for completed tasks
grep -c "\- \[x\]" "$SPEC_PATH/tasks.md" 2>/dev/null || echo "0"
grep -c "\- \[ \]" "$SPEC_PATH/tasks.md" 2>/dev/null || echo "0"
```

If no tasks are marked complete, OUTPUT:
```
No completed tasks found in tasks.md.

Please run /implement-tasks first to implement the specification.
```

### Step 3: Run verification

Use the **implementation-verifier** subagent to verify the implementation.

Provide the implementation-verifier with:
- The spec path: `agent-os/specs/[this-spec]`

Instruct the implementation-verifier to:
1. Verify all tasks are marked complete in tasks.md
2. Update the product roadmap if applicable
3. Run the entire test suite
4. Use Playwright MCP tools for browser-based UI verification if applicable
5. Create the final verification report

### Step 4: Report results

After verification completes:

**If running in chained mode (`--chained` in $ARGUMENTS):**

If verification PASSED:
```
VERIFY_IMPL_PASSED::[spec-path]::[passing tests]::[failing tests]
```

If verification found issues:
```
VERIFY_IMPL_FAILED::[spec-path]::[comma-separated list of issues]
```

**If running in standalone mode:**

If verification PASSED:
```
Implementation Verification Complete!

✅ All tasks verified complete
✅ Roadmap updated (if applicable)
✅ Test suite: [X] passing, [Y] failing

Final verification report: [spec-path]/verifications/final-verification.md

NEXT STEP 👉 Commit and push your changes to create a PR.
```

If verification found ISSUES:
```
Implementation Verification Complete - Issues Found

⚠️ Verification found issues:

Incomplete Tasks:
[List any incomplete tasks]

Failing Tests:
[List failing tests]

Missing Documentation:
[List missing docs]

Final verification report: [spec-path]/verifications/final-verification.md

Recommendations:
1. Complete any remaining tasks
2. Fix failing tests
3. Run `/verify-implementation` again
```

## Notes

- This command runs the full test suite
- It uses Playwright for browser-based testing when UI changes are involved
- The verification report documents the final state of the implementation
- Run this before creating a PR to ensure quality
