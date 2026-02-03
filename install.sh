#!/bin/bash
# Horadric Forge Installer (v1.0.2)
# Installs Codex Rules and configures Sari (Local Search) MCP.
# Supports standalone execution via curl.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }
echo_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Configuration
REPO_OWNER="BaeCheolHan"
FORGE_REPO="horadric-forge"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$FORGE_REPO/$BRANCH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT=""
FORCE_INSTALL="no"

# Resources (Will be downloaded if missing)
MANIFEST_FILE="$SCRIPT_DIR/manifest.toml"
TEMPLATE_FILE="$SCRIPT_DIR/templates/bootstrap.sh"

# Parse Args
RULES_SOURCE=""
TOOLS_SOURCE=""
IS_LOCAL_RULES="no"
IS_LOCAL_TOOLS="no"

for arg in "$@"; do
    case "$arg" in
        --force) FORCE_INSTALL="yes" ;;
        --rules-path=*) RULES_SOURCE="${arg#*=}"; IS_LOCAL_RULES="yes" ;;
        --tools-path=*) TOOLS_SOURCE="${arg#*=}"; IS_LOCAL_TOOLS="yes" ;;
        --global)
            echo "Sari Global Install Mode..."
            curl -fsSL https://raw.githubusercontent.com/BaeCheolHan/sari/main/install.py | python3
            exit 0
            ;;
        *)
            if [[ -z "$WORKSPACE_ROOT" && ! "$arg" == --* ]]; then
                WORKSPACE_ROOT="$arg"
            fi
            ;;
    esac
done

if [[ -z "$WORKSPACE_ROOT" ]]; then
    WORKSPACE_ROOT="$(pwd)"
fi

echo_info "Horadric Forge Installer (v1.0.2)"
echo_info "Workspace: $WORKSPACE_ROOT"

# -----------------------------------------------------------------------------
# 0. Resource Preparation (Remote Fetch)
# -----------------------------------------------------------------------------
# If running standalone, fetch manifest and template
prepare_resource() {
    local file_path=$1
    local remote_path=$2
    if [[ ! -f "$file_path" ]]; then
        echo_step "Fetching remote resource: $remote_path..."
        local dir=$(dirname "$file_path")
        mkdir -p "$dir"
        curl -sL -o "$file_path" "$BASE_URL/$remote_path" || {
            echo_error "Failed to download $remote_path"
            exit 1
        }
    fi
}

prepare_resource "$MANIFEST_FILE" "manifest.toml"
prepare_resource "$TEMPLATE_FILE" "templates/bootstrap.sh"

# -----------------------------------------------------------------------------
# 1. Pre-flight Check (Python & Unzip)
# -----------------------------------------------------------------------------
echo_step "시스템 환경 점검 중..."

# Check Python 3
if ! command -v python3 &>/dev/null; then
    echo_error "Python 3가 감지되지 않았습니다."
    echo "Sari(Local Search) 도구는 Python 3.8 이상이 필수입니다."
    
    if [[ ! -t 0 ]]; then
        echo_error "비대화형 모드: 설치를 중단합니다."
        exit 1
    fi
    
    read -rp "설치 가이드를 보시겠습니까? (Y/n) " choice
    if [[ "$choice" =~ ^[Yy] ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Mac OS 감지됨: 'brew install python3'를 실행해 보세요."
        else
            echo "공식 사이트: https://www.python.org/downloads/"
        fi
    fi
    exit 1
fi

# Check Python Version (3.8+)
if ! python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)"; then
    VER=$(python3 --version)
    echo_error "Python 버전이 너무 낮습니다: $VER"
    echo "3.8 이상의 버전이 필요합니다."
    exit 1
fi
echo_info "Python 환경 적합."

# Check Unzip
if ! command -v unzip &>/dev/null; then
    echo_error "unzip 명령어를 찾을 수 없습니다."
    echo "Sari 도구 설치를 위해 unzip이 필요합니다."
    exit 1
fi
echo_info "unzip 확인 완료."

# -----------------------------------------------------------------------------
# 2. Resolve Manifest
# -----------------------------------------------------------------------------
get_toml() {
    local query=$1
    local section=$(echo "$query" | cut -d"'" -f2)
    local key=$(echo "$query" | cut -d"'" -f4)
    
    python3 -c "
import sys
try:
    with open('$MANIFEST_FILE') as f:
        lines = f.readlines()
    
    target_sec = '$section'
    target_key = '$key'
    in_sec = False
    
    for line in lines:
        line = line.strip()
        # Section Header
        if line.startswith('[') and line.endswith(']'):
            curr = line[1:-1]
            in_sec = (curr == target_sec)
        # Key-Value pair
        elif in_sec and '=' in line and not line.startswith('#'):
            k, v = line.split('=', 1)
            if k.strip() == target_key:
                print(v.strip().strip('\"').strip(\"'\"))
                sys.exit(0)
except Exception:
    pass
"
}

if [[ -z "$RULES_SOURCE" ]]; then
    RULES_URL=$(get_toml "['rules']['url']")
    RULES_SOURCE="$RULES_URL"
    echo_info "Rules Source: Remote ($RULES_URL)"
else
    echo_info "Rules Source: Local ($RULES_SOURCE)"
fi

TOOL_VERSION=""
TOOL_URL=""
if [[ -z "$TOOLS_SOURCE" ]]; then
TOOL_VERSION=$(get_toml "['tools.sari']['version']")
TOOL_URL=$(get_toml "['tools.sari']['url']")
    echo_info "Sari Version: $TOOL_VERSION (Remote)"
else
    TOOL_VERSION="local-dev"
    TOOL_URL="" 
    echo_info "Sari Source: Local ($TOOLS_SOURCE)"
fi

# -----------------------------------------------------------------------------
# 3. Install Rules (Physical Copy)
# -----------------------------------------------------------------------------
echo_step "Ruleset 설치 중..."

TEMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

RULES_DIR="$TEMP_DIR/rules_content"
mkdir -p "$RULES_DIR"

if [[ "$IS_LOCAL_RULES" == "yes" ]]; then
    cp -R "$RULES_SOURCE/." "$RULES_DIR/"
else
    curl -sL -o "$TEMP_DIR/rules.zip" "$RULES_SOURCE"
    unzip -q "$TEMP_DIR/rules.zip" -d "$TEMP_DIR/rules_unzip"
    ZIP_ROOT=$(find "$TEMP_DIR/rules_unzip" -mindepth 1 -maxdepth 1 -type d | head -1)
    cp -R "$ZIP_ROOT/." "$RULES_DIR/"
fi

mkdir -p "$WORKSPACE_ROOT/.codex"
mkdir -p "$WORKSPACE_ROOT/.gemini"
mkdir -p "$WORKSPACE_ROOT/docs"

cp -R "$RULES_DIR/.codex/." "$WORKSPACE_ROOT/.codex/"
cp -R "$RULES_DIR/.gemini/." "$WORKSPACE_ROOT/.gemini/"
cp "$RULES_DIR/GEMINI.md" "$WORKSPACE_ROOT/" 2>/dev/null || true
if [[ -d "$RULES_DIR/docs/_shared" ]]; then
    mkdir -p "$WORKSPACE_ROOT/docs/_shared"
    cp -R "$RULES_DIR/docs/_shared/." "$WORKSPACE_ROOT/docs/_shared/"
fi

# -----------------------------------------------------------------------------
# 4. Install Sari (Global) + Cleanup Legacy
# -----------------------------------------------------------------------------
echo_step "Sari 설치/정리 중..."

LEGACY_DIR="$WORKSPACE_ROOT/.codex/tools/local-search"
OLD_DECKARD_DIR="$WORKSPACE_ROOT/.codex/tools/sari"

if [[ -d "$LEGACY_DIR" ]]; then
    echo_warn "구버전(local-search) 발견. 삭제합니다."
    rm -rf "$LEGACY_DIR"
fi
if [[ -d "$OLD_DECKARD_DIR" ]]; then
    echo_warn "구버전(.codex/tools/sari) 발견. 삭제합니다."
    rm -rf "$OLD_DECKARD_DIR"
fi

DECKARD_CMD=""
if [[ "$IS_LOCAL_TOOLS" == "yes" ]]; then
    DECKARD_CMD="$TOOLS_SOURCE/bootstrap.sh"
    if [[ ! -x "$DECKARD_CMD" ]]; then
        echo_error "Local tools path에 bootstrap.sh가 없습니다: $DECKARD_CMD"
        exit 1
    fi
    echo_info "Local Mode: Sari 실행 경로 = $DECKARD_CMD"
else
    echo_info "Sari 글로벌 설치 진행..."
    curl -fsSL https://raw.githubusercontent.com/BaeCheolHan/sari/main/install.py | python3
    DECKARD_CMD="$HOME/.local/share/sari/bootstrap.sh"
    if [[ ! -x "$DECKARD_CMD" ]]; then
        echo_error "Sari 설치가 완료되지 않았습니다: $DECKARD_CMD"
        exit 1
    fi
fi

echo_info "Sari 설치/정리 완료."

# -----------------------------------------------------------------------------
# 5. Configure CLIs (Multi-CLI)
# -----------------------------------------------------------------------------
echo_step "CLI 설정 주입 중..."

GEMINI_SETTINGS="$WORKSPACE_ROOT/.gemini/settings.json"
if [[ ! -f "$GEMINI_SETTINGS" ]]; then echo "{}" > "$GEMINI_SETTINGS"; fi

python3 -c "
import sys, json, os
try:
    path = '$GEMINI_SETTINGS'
    if os.path.exists(path):
        with open(path, 'r') as f: data = json.load(f)
    else: data = {}
    
    if 'mcpServers' not in data: data['mcpServers'] = {}
    
    data['mcpServers']['sari'] = {
        'command': '$DECKARD_CMD',
        'args': ['--workspace-root', '$WORKSPACE_ROOT'],
        'env': {'DECKARD_WORKSPACE_ROOT': '$WORKSPACE_ROOT'}
    }
    if 'local-search' in data['mcpServers']: del data['mcpServers']['local-search']

    with open(path, 'w') as f: json.dump(data, f, indent=2)
    print('Gemini settings updated.')
except Exception as e:
    print(f'Error updating gemini settings: {e}', file=sys.stderr)
    sys.exit(1)
"

CODEX_CONFIG="$WORKSPACE_ROOT/.codex/config.toml"
MCP_BLOCK=$(cat << 'EOF'

[mcp_servers.sari]
command = "$DECKARD_CMD"
args = ["--workspace-root", "$WORKSPACE_ROOT"]
env = { DECKARD_WORKSPACE_ROOT = "$WORKSPACE_ROOT" }
EOF
)

if [[ ! -f "$CODEX_CONFIG" ]]; then echo "# Codex Config" > "$CODEX_CONFIG"; fi
if ! grep -q "mcp_servers.sari" "$CODEX_CONFIG"; then
    echo "$MCP_BLOCK" >> "$CODEX_CONFIG"
    echo_info "Codex config updated."
fi

if [[ ! -f "$WORKSPACE_ROOT/AGENTS.md" ]]; then
    cat > "$WORKSPACE_ROOT/AGENTS.md" << 'EOF'
# Codex Rules
> Generated by Horadric Forge

## Instructions
1. **Core Rules**: `./.codex/rules/00-core.md`
2. **Context**: `./.codex/AGENTS.md` (if exists)

Please follow the rules defined in `.codex/rules`.
EOF
    echo_info "AGENTS.md created."
fi

echo_info "설치 완료!"
echo ""
echo "다음 단계:"
echo "  1. 'gemini' 또는 'codex' CLI를 실행하세요."
echo "  2. 실행 시 'sari' 도구가 자동으로 연결됩니다."
echo "  3. 로그 확인: ~/.local/share/sari/logs/sari.log"
