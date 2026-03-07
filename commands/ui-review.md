---
model: opus
description: Parallel user story validation — discovers YAML stories, fans out qa-agent instances, aggregates results
argument-hint: [headed] [filename-filter] [vision]
---

# Purpose

Discover user stories from YAML files, fan out parallel `qa-agent` instances to validate each story, then aggregate and report pass/fail results with screenshots.

## Variables

HEADED: $1 (default: "false" — set to "true" or "headed" for visible browser windows)
VISION: detected from $ARGUMENTS — if the keyword "vision" appears anywhere in the arguments, enable vision mode (screenshots returned as image responses in the agent's context for richer validation; higher token cost). Default: false.
FILENAME_FILTER: remaining non-keyword arguments after removing "vision" (if present)
STORIES_DIR: "ai_user_stories/web"
STORIES_GLOB: "ai_user_stories/web/*.yaml"
AGENT_TIMEOUT: 300000
SCREENSHOTS_BASE: "screenshots/qa"
RUN_DIR: "{SCREENSHOTS_BASE}/{YYYYMMDD_HHMMSS}_{short-uuid}" (generated once at start of run)

## Codebase Structure

```
ai_user_stories/
└── web/
    ├── login-flow.yaml
    └── *.yaml
screenshots/
└── qa/
    └── 20260306_143022_a1b2c3/        # Run directory (datetime + short uuid)
        ├── login-flow/                 # Source file stem
        │   ├── user-can-login/         # Slugified story name
        │   └── dashboard-loads/
        └── another-file/
            └── story-name/
```

## Instructions

- Use TeamCreate to create a team, then spawn one `qa-agent` teammate per story via the Task tool with `team_name` set to the team name
- Create a TaskCreate entry for each story so teammates can claim and track their work
- Launch ALL teammates in a single message so they run in parallel
- Be absolutely sure you clearly prompt each agent to have one specific task so all tasks get covered and you get results for every story
- If FILENAME_FILTER is provided and non-empty, only run stories from files whose name contains that substring
- If a YAML file fails to parse, log a warning and skip it — do not abort the entire run
- If no stories are found after discovery, report that and stop
- Be resilient: if a teammate times out or crashes, mark that story as FAIL and include whatever output was available
- The `subagent_type` for each Task call must be `qa-agent`
- After all teammates complete, send shutdown requests and call TeamDelete to clean up

## Workflow

### Phase 1: Discover

1. Use the Glob tool to find all files matching `STORIES_GLOB`
2. If `FILENAME_FILTER` is provided and non-empty, filter the file list to only include files whose name contains that substring
3. Read each YAML file and parse the `stories` array
4. If a file fails to parse, log a warning and skip it
5. Build a flat list of all stories across all files, tracking which source file each story came from
6. If no stories are found, report that and stop
7. Generate `RUN_DIR` using Bash:
   ```bash
   RUN_DIR="screenshots/qa/$(date +%Y%m%d_%H%M%S)_$(uuidgen | tr '[:upper:]' '[:lower:]' | head -c 6)"
   ```
8. For each story, build its `SCREENSHOT_PATH` by combining:
   - `RUN_DIR`
   - Source file stem (filename without `.yaml`)
   - Slugified story name (lowercase, spaces → hyphens)

   Example: `screenshots/qa/20260306_143022_a1b2c3/login-flow/user-can-login/`

### Phase 2: Spawn

9. Use TeamCreate to create a team named `ui-review`
10. Use TaskCreate to create one task per story, with the story name as subject and the full workflow as description
11. For each story, spawn a `qa-agent` teammate via the Task tool with `team_name: "ui-review"`. Launch ALL teammates in a single message so they run in parallel.
12. For each Task call, use this prompt:

```
Execute this user story and report results:

**Story:** {story.name}
**URL:** {story.url}
**Headed:** {HEADED}
**Vision:** {VISION}

**Workflow:**
{story.workflow}

Instructions:
- Follow each step in the workflow sequentially
- Take a screenshot after each significant step
- Save ALL screenshots to: {SCREENSHOT_PATH}
- Report each step as PASS or FAIL with a brief explanation
- At the end, provide a summary: total steps, passed, failed
- Use this exact format for your final summary line:
  RESULT: {PASS|FAIL} | Steps: {passed}/{total}
```

### Phase 3: Collect

13. Wait for teammate messages to arrive — they will be delivered automatically as each agent completes
14. Parse each teammate's report to extract:
    - Overall result: PASS or FAIL (look for the `RESULT:` line)
    - Steps completed vs total (from the `Steps: X/Y` portion)
    - The full agent report text
15. Mark each corresponding task as completed via TaskUpdate

### Phase 4: Cleanup and Report

16. Send shutdown requests to all teammates via SendMessage with `type: "shutdown_request"`
17. After all teammates have shut down, call TeamDelete to clean up
18. Output the report below

## Report

```
# UI Review Summary

**Run:** {current date and time}
**Stories:** {total} total | {passed} passed | {failed} failed
**Status:** ✅ ALL PASSED | ❌ PARTIAL FAILURE | ❌ ALL FAILED

## Results

| # | Story | Source File | Status | Steps |
| --- | --- | --- | --- | --- |
| 1 | {story name} | {filename} | ✅ PASS | {passed}/{total} |
| 2 | {story name} | {filename} | ❌ FAIL | {passed}/{total} |

## Failures

(Only include this section if there are failures)

### Story: {failed story name}
**Source:** {filename}
**Agent Report:**
{full agent report for this story}

---

## Screenshots
All screenshots saved to: `{RUN_DIR}/`
```

Use ✅ ALL PASSED only when every story passed. Use ❌ PARTIAL FAILURE when some passed and some failed. Use ❌ ALL FAILED when none passed.
