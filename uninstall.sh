#!/bin/bash
# Horadric Forge (v1.0.0) - 언인스톨 스크립트
# 사용법: ./uninstall.sh [workspace_root] [--force]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

FORCE=false
WORKSPACE_ROOT=""

for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=true ;;
        *) 
            if [[ -z "$WORKSPACE_ROOT" && ! "$arg" == --* ]]; then
                WORKSPACE_ROOT="$arg"
            fi
            ;;
    esac
done

if [[ -z "$WORKSPACE_ROOT" ]]; then
    if [[ -f ".codex-root" ]]; then
        WORKSPACE_ROOT="$(pwd)"
    else
        echo_error "Workspace root를 찾을 수 없습니다."
        echo "사용법: ./uninstall.sh [workspace_root]"
        exit 1
    fi
fi

WORKSPACE_ROOT="$(cd "$WORKSPACE_ROOT" 2>/dev/null && pwd)"

echo_info "Horadric Forge 언인스톨"
echo_info "Workspace: $WORKSPACE_ROOT"
echo ""

if [[ ! -f "$WORKSPACE_ROOT/.codex-root" ]]; then
    echo_error "Horadric Forge가 설치되어 있지 않습니다. (.codex-root 없음)"
    exit 1
fi

echo "다음 항목이 삭제됩니다:"
echo ""

ITEMS_TO_REMOVE=()
ITEMS_DESC=()

if [[ -f "$WORKSPACE_ROOT/.codex-root" ]]; then
    ITEMS_TO_REMOVE+=("$WORKSPACE_ROOT/.codex-root")
    ITEMS_DESC+=("  - .codex-root (마커 파일)")
fi

if [[ -d "$WORKSPACE_ROOT/.codex" ]]; then
    ITEMS_TO_REMOVE+=("$WORKSPACE_ROOT/.codex")
    ITEMS_DESC+=("  - .codex/ (룰셋, 도구, 설정)")
fi

if [[ -f "$WORKSPACE_ROOT/AGENTS.md" ]]; then
    ITEMS_TO_REMOVE+=("$WORKSPACE_ROOT/AGENTS.md")
    ITEMS_DESC+=("  - AGENTS.md (진입점)")
fi
if [[ -f "$WORKSPACE_ROOT/GEMINI.md" ]]; then
    ITEMS_TO_REMOVE+=("$WORKSPACE_ROOT/GEMINI.md")
    ITEMS_DESC+=("  - GEMINI.md (진입점)")
fi

if [[ -d "$WORKSPACE_ROOT/docs" ]]; then
    # docs/ 내부에 _shared 가 있거나 forge 관련 문서가 있는 경우 삭제 목록에 추가
    # 여기서는 안전하게 사용자에게 묻는 로직 유지
    if [[ "$FORCE" != true ]]; then
        read -rp "문서(docs/) 폴더도 삭제하시겠습니까? (yes/no) [no]: " remove_docs
        if [[ "$remove_docs" == "yes" || "$remove_docs" == "y" ]]; then
            ITEMS_TO_REMOVE+=("$WORKSPACE_ROOT/docs")
            ITEMS_DESC+=("  - docs/ (공유 문서)")
        fi
    else
        # Force 모드에서는 docs 삭제 안 함 (사용자 데이터 보호 우선)
        echo "  [KEEP] docs/ 폴더는 보존됩니다."
    fi
fi

# Sari 전역 캐시/인덱스 삭제
CACHE_DECKARD="$HOME/.local/share/sari"
CACHE_LEGACY="$HOME/.cache/local-search"

if [[ -d "$CACHE_DECKARD" ]]; then
    ITEMS_TO_REMOVE+=("$CACHE_DECKARD")
    ITEMS_DESC+=("  - $CACHE_DECKARD (전역 인덱스 DB)")
fi
if [[ -d "$CACHE_LEGACY" ]]; then
    ITEMS_TO_REMOVE+=("$CACHE_LEGACY")
    ITEMS_DESC+=("  - $CACHE_LEGACY (레거시 인덱스 DB)")
fi

for desc in "${ITEMS_DESC[@]}"; do echo "$desc"; done

echo ""

if [[ "$FORCE" != true ]]; then
    echo_warn "이 작업은 되돌릴 수 없습니다!"
    read -rp "정말 삭제하시겠습니까? (yes/no): " confirm
    if [[ "$confirm" != "yes" && "$confirm" != "y" ]]; then
        echo_info "언인스톨 취소됨"
        exit 0
    fi
fi

echo ""
echo_info "삭제 중..."

for item in "${ITEMS_TO_REMOVE[@]}"; do
    if [[ -e "$item" ]]; then
        rm -rf "$item"
        echo_info "  삭제됨: $item"
    fi
done

echo ""
echo_info "=========================================="
echo_info "언인스톨 완료!"
echo_info "=========================================="
echo ""