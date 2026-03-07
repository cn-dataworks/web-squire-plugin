# web-squire

Composable agentic UI testing, dashboard validation, and browser automation suite for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Built on the four-layer composable architecture from [Bowser](https://github.com/disler/bowser): Skill → Subagent → Command → Just.

## The Four-Layer Stack

| Layer | Name | Role | Where it lives |
|---|---|---|---|
| **4** | **Just** | Reusability — one command to run everything | `justfile` (in your project) |
| **3** | **Command** | Orchestration — discover stories, fan out agents, collect results | `commands/` |
| **2** | **Subagent** | Scale — parallel execution, isolated sessions, structured reporting | `agents/` |
| **1** | **Skill** | Capability — drive the browser via CLI or Chrome MCP | `skills/` |

You can enter at any layer. Test a skill directly, spawn a single agent, run a full orchestration command, or fire a one-liner from your justfile.

## Prerequisites

### Claude Code

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Playwright CLI

The playwright-cli skill requires [`playwright-cli`](https://github.com/microsoft/playwright-cli) — a token-efficient CLI for Playwright:

```bash
npm install -g @playwright/cli@latest
```

Verify:

```bash
playwright-cli --help
```

### Just (optional)

For Layer 4 reusability via justfile recipes:

```bash
brew install just
```

### Chrome MCP (optional)

For automating pages that require your existing browser session (SSO, cookies, extensions):

```bash
claude --chrome
```

## Skills

| Skill | Description |
|---|---|
| `playwright-cli` | Headless browser automation via `playwright-cli` binary. Parallel sessions, persistent profiles, vision mode opt-in. |
| `chrome-mcp` | Observable automation via Chrome MCP tools (`mcp__claude_in_chrome__*`). Uses your real Chrome with existing auth state. |

## Agents

| Agent | Description |
|---|---|
| `qa-agent` | QA validation — executes user stories step-by-step with pass/fail reporting and screenshots |
| `dashboard-tester` | Visual testing for Power BI / Tableau / canvas/SVG dashboards with vision mode |
| `data-gatherer` | Data extraction with pagination handling, monitoring thresholds, and alert flagging |

## Commands

| Command | Description |
|---|---|
| `/web-squire:ui-review` | Discover web stories, fan out qa-agents in parallel, aggregate results |
| `/web-squire:test-dashboards` | Discover dashboard stories, fan out dashboard-testers in parallel |
| `/web-squire:run-browser-automation` | Discover automation stories, fan out data-gatherers in parallel |
| `/web-squire:automate <workflow>` | Run a saved workflow with configurable skill/mode/vision |

## Project Setup

In the project where you use this plugin, create user story files:

```
your-project/
├── ai_user_stories/
│   ├── web/                         ← QA stories (for /ui-review)
│   │   └── login-flow.yaml
│   ├── dashboard/                   ← Dashboard stories (for /test-dashboards)
│   │   └── revenue-report.yaml
│   └── browser_automation/          ← Data gathering (for /run-browser-automation)
│       └── scrape-pricing.yaml
├── screenshots/                     ← Output (auto-created per run)
└── justfile                         ← Optional Layer 4 recipes
```

### Story File Format

Stories use a `stories` array with `name`, `url`, and `workflow` keys:

```yaml
stories:
  - name: "User can login"
    url: "https://myapp.example.com/login"
    workflow: |
      Navigate to https://myapp.example.com/login
      Verify the login page loads with username and password fields
      Enter username "testuser" and password "testpass"
      Click the Login button
      Verify the dashboard page loads
      Verify the user's name appears in the top-right corner

  - name: "Dashboard shows recent activity"
    url: "https://myapp.example.com/dashboard"
    workflow: |
      Navigate to https://myapp.example.com/dashboard
      Verify the dashboard loads with an activity feed
      Verify at least 3 activity items are visible
```

### Example Justfile

```just
default:
    @just --list

# Layer 1: Skill — direct playwright test
test-skill headed="true" prompt="Navigate to https://myapp.example.com and verify it loads":
    claude --dangerously-skip-permissions --model opus "/playwright-cli (headed: {{headed}}) {{prompt}}"

# Layer 2: Subagent — single QA agent
test-qa headed="true" prompt="Navigate to https://myapp.example.com/login. Verify login page loads. Enter test credentials. Click Login. Verify dashboard loads.":
    claude --dangerously-skip-permissions --model opus "Use a @qa-agent: (headed: {{headed}}) {{prompt}}"

# Layer 3: Command — parallel QA across all stories
ui-review headed="headed" filter="" *flags="":
    claude --dangerously-skip-permissions --model opus "/web-squire:ui-review {{headed}} {{filter}} {{flags}}"

# Layer 3: Command — parallel dashboard tests
test-dashboards:
    claude --dangerously-skip-permissions --model opus "/web-squire:test-dashboards"

# Layer 3: Command — parallel data gathering
run-automation:
    claude --dangerously-skip-permissions --model opus "/web-squire:run-browser-automation"
```

## How It Works

1. **You write YAML stories** in `ai_user_stories/` describing what to test.
2. **You run a command** (e.g., `/web-squire:ui-review` or `just ui-review`).
3. **The command discovers stories**, creates a team via TeamCreate, spawns one subagent per story via TaskCreate, and they all run in parallel.
4. **Each agent** opens its own browser session, executes steps, screenshots everything, and reports pass/fail.
5. **Results are aggregated** into a summary table with overall status, step counts, and screenshot paths.

> **Note:** Parallel fan-out (TeamCreate/TaskCreate) requires the experimental agent teams feature: `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
