# Spec Shaping Process

You are helping me brainstorm, explore, and shape a new feature idea. This is an **iterative discovery process** - we will explore the idea from multiple angles through conversation until I explicitly signal that feature discovery is complete.

This process will follow 3 main phases:

PHASE 1. Initialize spec folder
PHASE 2. Feature discovery (iterative brainstorming loop)
PHASE 3. Inform the user that discovery is complete

## Multi-Phase Process:

### PHASE 1: Initialize Spec

Use the **spec-initializer** subagent to initialize a new spec.

IF the user has provided a description, provide that to the spec-initializer.

The spec-initializer will provide the path to the dated spec folder (YYYY-MM-DD-spec-name) they've created.

### PHASE 2: Feature Discovery (Iterative Loop)

After spec-initializer completes, immediately use the **spec-shaper** subagent:

Provide the spec-shaper with:
- The spec folder path from spec-initializer

The spec-shaper will run an **iterative discovery loop**:

1. **Problem Space Exploration** - Understanding the pain point and context
2. **User Stories & Scenarios** - Who uses this and when
3. **Solution Exploration** - Approaches, scope, and trade-offs
4. **Deep Dives** - Data, edge cases, UX details, integrations
5. **Continue until complete** - Keep exploring until user signals done

**CRITICAL - Discovery Loop Behavior:**
- The spec-shaper will keep asking questions round after round
- It will go deeper with each round, exploring different dimensions
- It will challenge assumptions and explore alternatives
- It will periodically ask if user wants to continue or finalize
- **The loop ONLY ends when the user explicitly signals completion** by saying things like:
  - "Feature discovery is complete"
  - "I'm done brainstorming"
  - "Ready to finalize"
  - "That's enough questions"

**IMPORTANT**:
- The spec-shaper handles user interaction directly via AskUserQuestion tool
- You do NOT need to relay questions - the tool presents them to the user automatically
- Wait for the spec-shaper to complete ALL discovery rounds before proceeding
- This may take many rounds - that's expected and desired

### PHASE 3: Inform the user

After feature discovery is complete, inform the user:

```
Feature discovery complete!

✅ Spec folder created: `[spec-path]`
✅ Discovery session documented ([X] rounds of exploration)
✅ Visual assets: [Found X files / No files provided]
✅ Requirements captured in `requirements.md`

NEXT STEP 👉 Run `/write-spec` to generate the detailed specification document.
```
