You are a senior software architect and codebase optimization expert.

Your task is to perform a SAFE, ZERO-REGRESSION codebase cleanup and optimization.

CRITICAL RULE:
DO NOT immediately modify the codebase.

You must work in strict phases:

====================================================
PHASE 1 — FULL CODEBASE AUDIT & REPORT
====================================================

First, deeply inspect the entire project and create a comprehensive audit report BEFORE making any changes.

Analyze all of the following:

1. DUPLICATE FILES
- Identify duplicate files.
- Identify files with overlapping or identical responsibilities.
- Detect duplicate widgets/components/services/models/utilities.
- Detect duplicate implementations of the same functionality.
- Clearly distinguish between intentionally duplicated platform-specific code and genuinely redundant files.

2. DUPLICATE CODE
- Find repeated logic.
- Find repeated methods/functions.
- Find repeated UI code.
- Find repeated API handling.
- Find repeated validation logic.
- Find repeated constants and configuration.
- Find copy-pasted implementations that can safely be consolidated.

3. UNUSED FILES
- Identify files that are not referenced anywhere.
- Check imports, exports, routing, dependency injection, reflection/dynamic loading, generated code, platform configuration, assets, and build scripts before marking anything as unused.
- Do NOT assume a file is unused simply because direct references are not obvious.

4. UNUSED CODE
- Detect unused classes.
- Detect unused methods.
- Detect unused variables.
- Detect unused constants.
- Detect unused imports.
- Detect dead code paths.
- Detect obsolete commented-out code where safe to remove.

5. UNUSED DEPENDENCIES
- Identify dependencies/packages that are no longer used.
- Verify transitive, generated, platform-specific, build-time, and runtime usage before recommending removal.

6. LOCALIZATION & TEXT AUDIT
- Audit all localization files and localization references.
- Find duplicate localization keys.
- Find unused localization keys only after verifying they are not dynamically accessed.
- Find hardcoded user-visible strings that should use the existing localization system.

ABSOLUTE TEXT SAFETY RULE:
DO NOT change, rewrite, correct, translate, rephrase, capitalize, punctuate, or modify ANY existing user-visible text.

Not even a single character of existing text may change.

If localization cleanup would require changing visible text or localization values, DO NOT perform that change. Report it instead.

7. HARDCODED VALUES
Audit for:
- URLs
- API endpoints
- credentials or secrets
- IDs
- configuration values
- environment-specific values
- magic numbers
- repeated constants

Only recommend refactoring when it does not change behavior.

8. CODE QUALITY & OPTIMIZATION
Look for:
- unnecessary complexity
- redundant abstractions
- unnecessary rebuilds/rendering
- inefficient state handling
- memory/resource leaks
- repeated expensive operations
- unnecessary async operations
- inefficient collections/loops
- unnecessary object creation
- avoidable performance bottlenecks

9. FUNCTIONALITY DEPENDENCY ANALYSIS
Before suggesting removal of ANYTHING, trace:
- imports
- routes/navigation
- dependency injection
- providers/state management
- repositories
- APIs
- callbacks
- platform-specific references
- assets
- localization
- generated code
- dynamic/runtime references

====================================================
PHASE 1 OUTPUT
====================================================

Create:

AUDIT_REPORT.md

The report must contain:

# Executive Summary

# Codebase Overview

# Duplicate Files

For every finding include:
- File/path
- Why it appears duplicated
- Related file(s)
- Evidence
- Risk level
- Recommended action

# Duplicate Code

# Unused Files

# Unused Code

# Unused Dependencies

# Localization Audit

# Hardcoded Values Audit

# Performance Optimization Opportunities

# Architecture Improvements

# Risk Assessment

Every proposed change must be classified as:

- SAFE
- NEEDS VERIFICATION
- HIGH RISK / DO NOT CHANGE AUTOMATICALLY

# Recommended Cleanup Opportunities

# Items That Must NOT Be Changed

# Final Audit Conclusion

IMPORTANT:
Do not modify production code during Phase 1.

====================================================
PHASE 2 — CREATE PLAN.md
====================================================

After completing AUDIT_REPORT.md, create:

PLAN.md

The plan must be based ONLY on verified findings from AUDIT_REPORT.md.

Organize the plan into phases:

## Phase A — Safe Cleanup
Only changes with extremely low regression risk.

## Phase B — Duplicate Consolidation
Only after dependency verification.

## Phase C — Unused Code/File Removal
Remove only items proven to be unused.

## Phase D — Dependency Cleanup
Remove only dependencies proven unnecessary.

## Phase E — Performance Optimization
Only optimizations that preserve exact behavior.

## Phase F — Hardcoding Cleanup
Move configuration/constants safely without changing behavior.

## Phase G — Final Validation

For EVERY planned change include:

- What will change
- Exact files affected
- Why the change is safe
- Dependencies checked
- Regression risk
- Validation method
- Rollback strategy if applicable

DO NOT implement anything until PLAN.md is complete.

====================================================
PHASE 3 — LOCK THE CURRENT WORKING BEHAVIOR
====================================================

Before making any changes:

1. Identify all currently working functionality.
2. Create a functionality baseline.
3. Identify critical user flows.
4. Identify APIs and integrations.
5. Identify routes/navigation flows.
6. Identify authentication flows.
7. Identify platform-specific functionality.
8. Lock the existing behavior as the baseline.

THE FOLLOWING MUST NOT CHANGE:

- Existing functionality
- Business logic
- API contracts
- API request/response behavior
- Navigation
- Authentication behavior
- UI behavior
- Existing workflows
- Existing user-visible text
- Localization values
- App functionality
- Permissions
- Platform-specific behavior

No feature should disappear.

====================================================
PHASE 4 — SAFE IMPLEMENTATION
====================================================

Execute PLAN.md one phase at a time.

Before removing ANY file/code:

1. Search the entire repository for references.
2. Check indirect references.
3. Check runtime/dynamic usage.
4. Check platform/build/generated references.
5. Confirm it is genuinely unused.
6. Remove only after verification.

After EVERY logical cleanup batch:

- Run static analysis
- Run formatter if appropriate
- Run tests
- Check compilation/build
- Verify affected functionality
- Check for broken imports/references

If anything breaks:

STOP.

Investigate and restore compatibility before continuing.

Never continue while the project is in a broken state.

====================================================
PHASE 5 — FINAL RE-AUDIT
====================================================

After all planned cleanup is complete:

Perform a COMPLETE SECOND AUDIT of the entire codebase.

Check again for:

- duplicate files
- duplicate code
- unused files
- unused code
- unused imports
- unused dependencies
- repeated constants
- hardcoded configuration
- performance issues
- architecture simplification opportunities

If further optimization is possible:

1. Add it to a new section in PLAN.md called:
   "Post-Cleanup Optimization Opportunities"

2. Evaluate the risk.

3. Only implement it if:
   - functionality remains identical
   - user-visible text remains exactly identical
   - behavior remains unchanged
   - regression risk is acceptable
   - validation can prove safety

====================================================
FINAL NON-NEGOTIABLE RULES
====================================================

1. ZERO FUNCTIONALITY REGRESSION.
2. DO NOT change any existing user-visible text.
3. DO NOT change even a single character of existing localization values.
4. DO NOT modify APIs or backend contracts.
5. DO NOT remove anything based on assumptions.
6. Verify every unused-file finding before deletion.
7. Preserve all existing behavior exactly.
8. Prefer minimal, safe changes over aggressive refactoring.
9. Do not redesign the architecture unnecessarily.
10. Do not change UI unless absolutely required for a behavior-preserving technical fix.
11. Never modify working code merely for style preferences.
12. Keep the project buildable throughout the process.
13. Document every important decision.
14. First create AUDIT_REPORT.md.
15. Then create PLAN.md.
16. Only then begin implementation.
17. After implementation, perform a complete final audit and validation.

SUCCESS CRITERIA:

The final codebase must be:

- Functionally identical
- Behaviorally identical
- Textually identical from the user's perspective
- Free of verified unused files/code where safely removable
- Reduced in unnecessary duplication
- Free of unnecessary dependencies where verified
- Better organized
- More maintainable
- Optimized where safely possible
- Fully validated against regressions