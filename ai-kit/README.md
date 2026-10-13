# ai-kit — one set of rules for Claude Code, Antigravity and Copilot

You write the rules once in `AGENTS.md`, and all three tools read them:

| Tool | How it reads the rules |
|---|---|
| Claude Code | `CLAUDE.md` contains `@AGENTS.md`, which imports the file |
| Antigravity | reads the root `AGENTS.md` itself; `.agents/rules/project.md` points it there too |
| GitHub Copilot | VS Code agent mode reads `AGENTS.md` (setting `chat.useAgentsMdFile`); `ai-sync.sh` generates `.github/copilot-instructions.md` for Copilot code review and the coding agent |

## Add it to a repo (run in the repo root)

```bash
curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/install.sh | bash
```

The script never overwrites existing files (set `FORCE=1` if you want it to). It detects npm, pnpm, yarn or bun and fills in the project name. Then:

1. Ask Claude Code: *"Fill the {{…}} placeholders in AGENTS.md from this codebase."*
2. Run `bash ai-sync.sh` every time you edit `AGENTS.md`.

It also adds `.claude/settings.json`, which:

- allows everyday commands without a prompt (tests, lint, git status/diff/commit)
- blocks `.env` reads, `rm -rf` and force-push
- runs Prettier after every edit

## One-time setup on your Mac

```bash
curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/install-global.sh | bash
```

This writes `~/.claude/CLAUDE.md` and `~/.gemini/GEMINI.md` (personal rules for every project). Then merge `vscode/settings.json` into your VS Code and Antigravity user settings.

## Testing + CI/CD
See [TESTING-CICD.md](TESTING-CICD.md). It sets up Vitest, Testing Library and Playwright, CI on GitHub Actions, deploy to Coolify, and Claude PR review. One command per repo:

```bash
curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-testing.sh | bash
```

## Git automation (commit → push → PR → auto-merge → deploy)
See [GIT-AUTOMATION.md](GIT-AUTOMATION.md).
```bash
curl -fsSL https://raw.githubusercontent.com/arefur/.github/main/ai-kit/setup-automation.sh | bash
npm run ship -- "feat(scope): what changed"
```
