# web-squire

Composable agentic UI testing, dashboard validation, and browser automation suite for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Built on the four-layer composable architecture from [Bowser](https://github.com/disler/bowser): Skill → Subagent → Command → Just.

## Quick Start

Get from zero to running tests in 5 minutes.

### 1. Install the plugin

Inside Claude Code:

```
/plugin marketplace add https://github.com/cn-dataworks/web-squire-plugin
/plugin install web-squire
```

See [INSTALL.md](INSTALL.md) for alternative install methods and full details.

### 2. Install Playwright CLI

```bash
npm install -g @playwright/cli@latest
playwright-cli --help   # verify it works
```

### 3. Create a story file

In your project, create `ai_user_stories/web/smoke-test.yaml`:

```yaml
stories:
  - name: "Homepage loads correctly"
    url: "https://myapp.example.com"
    workflow: |
      Navigate to https://myapp.example.com
      Verify the page loads without errors
      Verify a navigation bar is visible at the top
      Verify the main content area contains a heading
```

### 4. Run the tests

```
/web-squire:ui-review
```

### 5. What to expect

The command discovers your story files, spawns one QA agent per story, and each agent:
- Opens a browser session
- Executes your workflow steps sequentially
- Screenshots every step to `screenshots/qa/`
- Reports a pass/fail summary table

```
✅ SUCCESS

**Story:** Homepage loads correctly
**Steps:** 4/4 passed
**Screenshots:** ./screenshots/qa/homepage-loads-correctly_a1b2c3d4/

| # | Step | Status | Screenshot |
| --- | --- | --- | --- |
| 1 | Navigate to homepage | PASS | 00_navigate.png |
| 2 | Verify page loads | PASS | 01_page-loads.png |
| 3 | Verify nav bar | PASS | 02_nav-bar.png |
| 4 | Verify heading | PASS | 03_heading.png |

RESULT: PASS | Steps: 4/4
```

## Which Command Do I Use?

| I want to... | Command | Story directory |
|---|---|---|
| Test UI workflows (login, forms, navigation) | `/web-squire:ui-review` | `ai_user_stories/web/` |
| Validate dashboards visually (Power BI, Tableau) | `/web-squire:test-dashboards` | `ai_user_stories/dashboard/` |
| Scrape data or monitor pages | `/web-squire:run-browser-automation` | `ai_user_stories/browser_automation/` |
| Run a single saved workflow | `/web-squire:automate <file>` | Any path |

## Which Skill Do I Need?

| Situation | Use | Why |
|---|---|---|
| Standard web testing (default) | `playwright-cli` | Headless, fast, supports parallel sessions |
| Site requires SSO/cookies/extensions | `chrome-mcp` | Uses your real Chrome session with existing auth |
| Not sure | `playwright-cli` | Works for 90% of cases |

> **Note:** When using commands (Layer 3), you don't pick skills directly — the agents choose automatically. Skill selection matters when you invoke skills directly at Layer 1.

## Story File Format

Stories use a `stories` array with `name`, `url`, and `workflow` keys. The `workflow` field is natural language — be specific about what to verify.

### QA story (for `/web-squire:ui-review`)

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

### Dashboard story (for `/web-squire:test-dashboards`)

Dashboard tests use vision mode automatically — the agent screenshots each step and visually reads chart values, KPIs, and filter states from the image.

```yaml
stories:
  - name: "Revenue dashboard shows correct Q4 data"
    url: "https://app.powerbi.com/reports/abc123/ReportSection"
    workflow: |
      Navigate to the revenue dashboard
      Verify the dashboard loads with at least 3 chart tiles
      Click the Q4 filter button
      Verify the revenue chart updates to show Q4 data
      Verify the KPI card shows revenue above $2M
      Hover over the trend line chart and verify the tooltip shows monthly values
```

### Data gathering story (for `/web-squire:run-browser-automation`)

```yaml
stories:
  - name: "Scrape competitor pricing"
    url: "https://competitor.example.com/pricing"
    output_format: "markdown_table"
    monitoring_threshold:
      price_change_pct: 10
    workflow: |
      Navigate to https://competitor.example.com/pricing
      Extract all plan names and prices from the pricing table
      If there is a "Show more" or pagination control, click through all pages
      Output the complete pricing data as a markdown table
      Flag any prices that differ by more than 10% from previous values
```

### Tips for writing good workflows

- **Be specific about verifications** — "Verify the nav bar exists" is better than "Check the page"
- **Include exact URLs** — don't assume the agent knows where to go
- **Describe what success looks like** — "Verify at least 3 items" instead of "Verify items exist"
- **Use natural language** — the agent also accepts BDD (Given/When/Then), checklists, and step-by-step imperative formats

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
├── screenshots/                     ← Output (auto-created per run, gitignored)
└── justfile                         ← Optional Layer 4 recipes
```

The `screenshots/` directory is created automatically during test runs. Add it to your `.gitignore`:

```
screenshots/
```

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

## Example Justfile

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

## Troubleshooting

### `playwright-cli` not found

```bash
npm install -g @playwright/cli@latest
```

If it installs but still isn't found, check that your npm global bin directory is in your `PATH`:

```bash
npm config get prefix    # shows the install prefix
# Add <prefix>/bin to your PATH if needed
```

### Browser doesn't open (headed mode)

By default, `playwright-cli` runs headless. To see the browser, pass `headed: true` in your command or justfile recipe. If you're running inside a remote/SSH session, headed mode won't work — use headless.

### Chrome MCP tools not available

Make sure you started Claude Code with Chrome support:

```bash
claude --chrome
```

The `mcp__claude_in_chrome__*` tools should then appear in your tool list. If they don't, check that Chrome is running and accessible.

### Stories not discovered

Commands look for stories in exact directory names:
- `/web-squire:ui-review` → `ai_user_stories/web/`
- `/web-squire:test-dashboards` → `ai_user_stories/dashboard/`
- `/web-squire:run-browser-automation` → `ai_user_stories/browser_automation/`

Check that your directory names match exactly and that your YAML files contain a `stories:` array.

### Parallel fan-out not working

Agent teams require an experimental flag:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Without this, commands will run stories sequentially instead of in parallel.
