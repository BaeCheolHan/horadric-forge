# Horadric Forge Separation Completed (v2.6.0)

> **Date**: 2026-01-31
> **Status**: COMPLETED
> **Result**: Monorepo split into 3 independent repositories.

## 1. Repository Structure
All repositories have been created at the root level (`/Users/baecheolhan/Documents/repositories/`).

### `horadric-forge-rules`
Contains the "Soul" of the AI Agent (Rules, Scenarios, Skills).
- `.codex/` (Core rules)
- `.gemini/` (Gemini specific rules & settings)
- `docs/_shared/` (Operational docs)
- `GEMINI.md`

### `horadric-deckard`
Contains the "Eyes" of the AI Agent (Local Search Tool).
- `app/`, `mcp/` (Python source code)
- `config/` (Default configs)
- Root path validation & Local DB path enforcement applied.

### `horadric-forge`
Contains the "Hammer" (Installer).
- `install.sh`: Completely rewritten to support ZIP/Local sources.
- `manifest.toml`: Version pinning.

## 2. DoD Verification Results

| Item | Result | Note |
|------|--------|------|
| **Independent Install** | ✅ PASS | `install.sh` successfully installed from split repos. |
| **Cross-CLI Support** | ✅ PASS | Both `.codex` and `.gemini` rules are installed. |
| **MCP Safety** | ✅ PASS | `${cwd}` validation added, DB path forced to local. |
| **MCP Execution** | ✅ PASS | `server.py` starts correctly in `test-workspace`. |
| **Hidden Files** | ✅ PASS | `.codex` and `.gemini` contents copied correctly. |

## 3. How to Install (For Users)

```bash
# Clone the installer repo
git clone https://github.com/BaeCheolHan/horadric-forge.git
cd horadric-forge

# Install to your workspace
./install.sh /path/to/your/project
```

## 4. Development Commands (For Maintainers)

To test changes locally without pushing to Git:

```bash
./horadric-forge/install.sh ./test-workspace \
  --rules-path=../horadric-forge-rules \
  --tools-path=../horadric-deckard \
  --force
```
