# Installing the Web Squire Plugin

This plugin provides composable agentic UI testing, dashboard validation, and browser automation for Claude Code.

---

## Quick Install

### Option A: Direct Install (Recommended)

Run these commands inside Claude Code:

```
/plugin marketplace add https://github.com/cn-dataworks/web-squire-plugin
/plugin install web-squire
```

That's it! The plugin is now available in all your projects.

### Option B: Git Clone (For Contributors)

If you plan to contribute or want more control:

```powershell
# 1. Clone the repository
git clone https://github.com/cn-dataworks/web-squire-plugin.git "$HOME\.claude\plugins\custom\web-squire"

# 2. Run installer (registers with Claude Code + checks prerequisites)
cd "$HOME\.claude\plugins\custom\web-squire"
.\install-plugin.ps1
```

Choose **"Install for you"** when prompted (installs globally for all projects).

### Verify

Open Claude Code and verify the installation:

```powershell
claude
```

```
/plugin list
```

You should see `web-squire` listed.

---

## Prerequisites

### Required

- **Claude Code** (latest version)
- **Playwright CLI** — token-efficient CLI for browser automation:
  ```bash
  npm install -g @playwright/cli@latest
  playwright-cli --help
  ```

### Optional

- **Just** — for Layer 4 justfile recipes:
  ```bash
  brew install just        # macOS
  choco install just       # Windows
  ```
- **Chrome MCP** — for automating pages with your existing browser session (SSO, cookies):
  ```bash
  claude --chrome
  ```

---

## Project Setup

In the project where you use this plugin, create user story files:

```
your-project/
├── ai_user_stories/
│   ├── web/                         <- QA stories (for /ui-review)
│   │   └── login-flow.yaml
│   ├── dashboard/                   <- Dashboard stories (for /test-dashboards)
│   │   └── revenue-report.yaml
│   └── browser_automation/          <- Data gathering (for /run-browser-automation)
│       └── scrape-pricing.yaml
├── screenshots/                     <- Output (auto-created per run)
└── justfile                         <- Optional Layer 4 recipes
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
```

---

## Verification

1. **Plugin listed**: `/plugin list` shows `web-squire`
2. **Playwright CLI works**: `playwright-cli --help` returns usage info
3. **Try a skill**: Ask Claude to navigate to a URL using the playwright-cli skill
4. **Try a command**: `/web-squire:ui-review` (requires story files in your project)

---

## Updating

### If You Used Option A (Direct Install)

Inside Claude Code:
```
/plugin update web-squire
```

### If You Used Option B (Git Clone)

```powershell
cd "$HOME\.claude\plugins\custom\web-squire"
git pull
```

---

## Troubleshooting

### Plugin not showing in /plugin list

```powershell
cd "$HOME\.claude\plugins\custom\web-squire"
.\install-plugin.ps1
```

Or manually register inside Claude Code:
```
/plugin marketplace add ~/.claude/plugins/custom/web-squire
/plugin install web-squire
```

### Playwright CLI not found

```bash
npm install -g @playwright/cli@latest
```

Verify it's in your PATH:
```bash
playwright-cli --help
```

### Need more help?

[Open an issue](https://github.com/cn-dataworks/web-squire-plugin/issues)

---

## Uninstalling

Inside Claude Code:
```
/plugin uninstall web-squire
```

Then delete the files:
```powershell
Remove-Item -Recurse -Force "$HOME\.claude\plugins\custom\web-squire"
```
