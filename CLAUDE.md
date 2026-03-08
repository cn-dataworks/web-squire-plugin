# Web Squire Plugin

Claude Code plugin for composable agentic UI testing, dashboard validation, and browser automation.

> **Note:** This CLAUDE.md is for **plugin developers**, not end users.

## Documentation Quick Reference

| What You Need | Where to Find It |
|---------------|------------------|
| **Playwright CLI skill** | `skills/playwright-cli/SKILL.md` |
| **Chrome MCP skill** | `skills/chrome-mcp/SKILL.md` |
| **Agent definitions** | `agents/*.md` |
| **Command orchestrations** | `commands/*.md` |
| **Plugin manifest** | `.claude-plugin/plugin.json` |
| **Installation guide** | `INSTALL.md` |

## What It Does

Two skills, three agents, four commands — composed via the Bowser four-layer stack.

### Skills

| Skill | Purpose |
|-------|---------|
| `playwright-cli` | Headless browser automation via `playwright-cli` binary |
| `chrome-mcp` | Observable automation via Chrome MCP (uses real Chrome session) |

### Agents

| Agent | Purpose |
|-------|---------|
| `qa-agent` | QA validation — step-by-step story execution with pass/fail |
| `dashboard-tester` | Visual testing for BI dashboards with vision mode |
| `data-gatherer` | Data extraction with pagination and alert flagging |

### Commands

| Command | Purpose |
|---------|---------|
| `/web-squire:ui-review` | Fan out qa-agents across web stories in parallel |
| `/web-squire:test-dashboards` | Fan out dashboard-testers across dashboard stories |
| `/web-squire:run-browser-automation` | Fan out data-gatherers across automation stories |
| `/web-squire:automate` | Run a saved workflow with configurable skill/mode/vision |

## Architecture

Four-layer composable stack (from Bowser):

```
Layer 4: Just        — one command to run everything (justfile)
Layer 3: Command     — orchestration, fan-out, aggregation (commands/)
Layer 2: Subagent    — parallel execution, isolated sessions (agents/)
Layer 1: Skill       — browser automation capability (skills/)
```

## Git Safety (Public Repository)

This is a **public repository**. Before any `git push`, scan all staged changes for sensitive information:

- API keys, tokens, secrets, passwords
- Internal URLs, IP addresses, hostnames
- User-specific paths or credentials
- `.env` files, connection strings, auth configs

If anything sensitive is found, **stop and flag it** before pushing.

## Key Conventions

- Stories live in the consuming project's `ai_user_stories/` directory
- Screenshots go to `screenshots/` (gitignored, generated per run)
- Commands discover stories via glob, spawn one agent per story
- Parallel fan-out uses TeamCreate/TaskCreate (experimental agent teams)
