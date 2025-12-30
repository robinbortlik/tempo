# Build Feature (Alias)

Shortcut for `/agent-os/build-feature`.

Run the complete end-to-end feature development workflow.

## Usage

Simply run `/build` with an optional feature description:

```
/build Add user preferences page
```

Or run without arguments to be guided through the process:

```
/build
```

## Process

This command executes the full AgentOS workflow:

1. **Shape** - Gather requirements interactively
2. **Spec** - Write detailed specification
3. **Tasks** - Create implementation task list
4. **Verify** - Validate spec against requirements
5. **Implement** - Build all features
6. **Test** - Run verification and tests
7. **Ship** - Commit, push, and optionally create PR

See `/agent-os/build-feature` for full documentation.

---

**Delegate to:** Run `/agent-os/build-feature $ARGUMENTS`
