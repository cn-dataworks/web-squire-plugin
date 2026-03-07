---
model: opus
description: Parallel dashboard validation — discovers dashboard YAML stories, fans out dashboard-tester agents, aggregates visual testing results
argument-hint: [headed] [filename-filter] [vision]
---

# Purpose

Discover dashboard test stories from YAML files, fan out parallel `dashboard-tester` instances to validate each, then aggregate and report pass/fail results with screenshots.

## Variables

HEADED: $1 (default: "true" — dashboards are typically tested visibly)
VISION: default "true" — dashboards require visual inspection. Can be overridden via $ARGUMENTS.
FILENAME_FILTER: remaining non-keyword arguments
STORIES_DIR: "ai_user_stories/dashboard"
STORIES_GLOB: "ai_user_stories/dashboard/*.yaml"
AGENT_TIMEOUT: 300000
SCREENSHOTS_BASE: "screenshots/dashboard"
RUN_DIR: "{SCREENSHOTS_BASE}/{YYYYMMDD_HHMMSS}_{short-uuid}" (generated once at start of run)

## Instructions

- Use TeamCreate to create a team, then spawn one `dashboard-tester` teammate per story via the Task tool
- Create a TaskCreate entry for each story
- Launch ALL teammates in a single message so they run in parallel
- The `subagent_type` for each Task call must be `dashboard-tester`
- If FILENAME_FILTER is provided, only run stories from files whose name contains that substring
- If a YAML file fails to parse, log a warning and skip it
- Be resilient: if a teammate times out or crashes, mark that story as FAIL
- After all teammates complete, send shutdown requests and call TeamDelete to clean up

## Workflow

### Phase 1: Discover

1. Use the Glob tool to find all files matching `STORIES_GLOB`
2. Apply FILENAME_FILTER if provided
3. Read each YAML file and parse the `stories` array
4. Build a flat list of all stories, tracking source files
5. If no stories found, report that and stop
6. Generate `RUN_DIR`:
   ```bash
   RUN_DIR="screenshots/dashboard/$(date +%Y%m%d_%H%M%S)_$(uuidgen | tr '[:upper:]' '[:lower:]' | head -c 6)"
   ```
7. Build `SCREENSHOT_PATH` for each story: `{RUN_DIR}/{file-stem}/{slugified-name}/`

### Phase 2: Spawn

8. Use TeamCreate to create a team named `dashboard-review`
9. For each story, spawn a `dashboard-tester` teammate with this prompt:

```
Execute this dashboard test and report results:

**Dashboard:** {story.name}
**URL:** {story.url}
**Headed:** {HEADED}
**Vision:** true

**Workflow:**
{story.workflow}

Instructions:
- Follow each step sequentially
- Take a screenshot after every interaction (filters, hovers, navigation)
- Save ALL screenshots to: {SCREENSHOT_PATH}
- Visually verify all chart data, KPI values, and filter behavior
- Report each step with your visual finding as PASS or FAIL
- Use this exact format for your final summary line:
  RESULT: {PASS|FAIL} | Steps: {passed}/{total}
```

### Phase 3: Collect

10. Wait for all teammates to complete
11. Parse each report for `RESULT:` line and step counts
12. Mark tasks as completed

### Phase 4: Cleanup and Report

13. Send shutdown requests, call TeamDelete
14. Output the report:

```
# Dashboard Test Summary

**Run:** {current date and time}
**Dashboards:** {total} total | {passed} passed | {failed} failed
**Status:** ✅ ALL PASSED | ❌ PARTIAL FAILURE | ❌ ALL FAILED

## Results

| # | Dashboard | Source File | Status | Steps |
| --- | --- | --- | --- | --- |
| 1 | {name} | {filename} | ✅ PASS | {passed}/{total} |
| 2 | {name} | {filename} | ❌ FAIL | {passed}/{total} |

## Failures
(Only if there are failures — include full agent report)

## Screenshots
All screenshots saved to: `{RUN_DIR}/`
```
