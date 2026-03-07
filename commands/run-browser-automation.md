---
model: opus
description: Parallel data gathering — discovers automation YAML stories, fans out data-gatherer agents, aggregates results with monitoring alerts
argument-hint: [filename-filter]
---

# Purpose

Discover browser automation stories from YAML files, fan out parallel `data-gatherer` instances, then aggregate extracted data and prominently highlight any monitoring threshold alerts.

## Variables

FILENAME_FILTER: $1 (optional — filter to files whose name contains this substring)
STORIES_DIR: "ai_user_stories/browser_automation"
STORIES_GLOB: "ai_user_stories/browser_automation/*.yaml"
AGENT_TIMEOUT: 300000

## Instructions

- Use TeamCreate to create a team, then spawn one `data-gatherer` teammate per story via the Task tool
- Create a TaskCreate entry for each story
- Launch ALL teammates in a single message so they run in parallel
- The `subagent_type` for each Task call must be `data-gatherer`
- If FILENAME_FILTER is provided, only run stories from files whose name contains that substring
- If a YAML file fails to parse, log a warning and skip it
- Be resilient: if a teammate times out or crashes, mark that task as Error
- After all teammates complete, send shutdown requests and call TeamDelete to clean up

## Workflow

### Phase 1: Discover

1. Use the Glob tool to find all files matching `STORIES_GLOB`
2. Apply FILENAME_FILTER if provided
3. Read each YAML file and parse the `stories` array
4. Build a flat list of all tasks, tracking source files
5. If no stories found, report that and stop

### Phase 2: Spawn

6. Use TeamCreate to create a team named `browser-automation`
7. For each story, spawn a `data-gatherer` teammate with this prompt:

```
Execute this data gathering task:

**Task:** {story.name}
**URL:** {story.url}

**Workflow:**
{story.workflow}

**Output Format:** {story.output_format or "markdown table"}
**Monitoring Threshold:** {story.monitoring_threshold or "none"}

Instructions:
- Follow the workflow steps
- Handle pagination if needed — collect ALL data, not just the first page
- If a monitoring_threshold is provided, compare values and flag anomalies
- Output the extracted data in the requested format
- Do not output script code — only output the data
```

### Phase 3: Collect

8. Wait for all teammates to complete
9. Gather extracted data and monitoring alerts from each agent

### Phase 4: Cleanup and Report

10. Send shutdown requests, call TeamDelete
11. Output the report:

```
# Browser Automation Summary

**Run:** {current date and time}
**Tasks:** {total} total | {completed} completed | {errored} errored

## Results

| # | Task | Source File | Status | Alerts |
| --- | --- | --- | --- | --- |
| 1 | {name} | {filename} | Complete | — |
| 2 | {name} | {filename} | Complete | ⚠ 2 alerts |
| 3 | {name} | {filename} | Error | Failed to paginate |
```

**Prominently highlight any monitoring threshold alerts:**

```
### ⚠ Monitoring Alerts

| Task | Metric | Current | Threshold | Status |
| --- | --- | --- | --- | --- |
| {name} | {metric} | {value} | {threshold} | ⚠ BELOW/ABOVE THRESHOLD |
```

12. Output all gathered data in the requested formats (do not output automation scripts or code).
