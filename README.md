# ⚒️ Horadric Forge

> **"Stay awhile and listen..."**
>
> **Horadric Forge**는 **Codex / Gemini / Claude** 기반의 AI 코딩 환경을 구축하기 위한 통합 설치 도구(Installer & Manager)입니다.
> 번거로운 설정 없이 표준화된 **규칙(Rules)**과 강력한 **검색 도구(Sari)**를 한 번에 주입합니다.

## ✨ Features

- **📂 Project Bootstrap**: 현재 프로젝트에 `.codex`/`.gemini` 표준 규칙과 설정을 자동으로 구성합니다.
- **🔍 Sari Integration**: 초고속 로컬 코드 검색 엔진 [Sari](https://github.com/BaeCheolHan/sari)를 자동으로 설치하고 연동합니다.
- **⚡ Zero Config**: 설치 스크립트 실행 한 번으로 모든 준비가 끝납니다.
- **🌐 Global Support**: 특정 프로젝트가 아닌, 시스템 전역(Global) 도구로 Sari를 설치하고 Claude Desktop과 연동할 수 있습니다.

---

## 🚀 사용법 (Usage)

터미널에서 아래 명령어 한 줄만 입력하면 됩니다.

### 1. 프로젝트 설정 (Project Setup)
현재 작업 중인 프로젝트 디렉토리에서 실행하세요. 해당 프로젝트에 **Rules**와 **Local Search(Sari)** 환경을 구축합니다.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BaeCheolHan/horadric-forge/main/install.sh)"
```

> **설치되는 항목:**
> - `.codex/rules/` : 표준 코딩 규칙 (Horadric Rules)
> - `~/.local/share/sari/` : 로컬 검색용 MCP 서버 (Global)
> - `.gemini/settings.json` / `.codex/config.toml` : CLI 도구 연동 설정

### 2. 글로벌 도구 설치 (Global Tool Setup)
프로젝트와 무관하게, **Sari(검색 도구)**만 시스템 전역(`~/.local/share`)에 설치하고 **Claude Desktop** 등과 연동하고 싶다면 `--global` 옵션을 사용하세요.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BaeCheolHan/horadric-forge/main/install.sh)" -- --global
```

---

## 📦 구성 요소 (Components)

Horadric Forge는 다음 두 가지 핵심 구성 요소를 관리합니다.

| Component | Repository | Description |
|-----------|------------|-------------|
| **📜 Rules** | [Horadric Rules](https://github.com/BaeCheolHan/horadric-forge-rules) | 효율적인 AI 코딩을 위한 표준 프롬프트 & 규칙 세트 |
| **🧙‍♂️ Sari** | [Sari](https://github.com/BaeCheolHan/sari) |  SQLite + FTS5 기반의 로컬 코드 문맥 검색 엔진 (MCP 지원) |

**`manifest.toml`** 파일을 통해 각 구성 요소의 버전을 엄격하게 관리하며, 설치 시 항상 검증된 버전을 제공합니다.

---

## 🛠 고급 옵션 (Advanced)

### 특정 경로 지정
```bash
# 특정 디렉토리에 설치
./install.sh /path/to/my-project

# 로컬에 있는 Rules/Tools 소스로 설치 (개발용)
./install.sh --rules-path=../horadric-forge-rules --tools-path=../sari
```

### 강제 재설치
```bash
./install.sh --force
```

---

## 📜 License

[MIT License](LICENSE)
