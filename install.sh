#!/usr/bin/env bash
# install.sh — Install claude-docs skills into user or project directories
#
# Usage:
#   ./install.sh setup                                  # Install user-level skills + universal CLAUDE.md
#   ./install.sh /path/to/project java spring-boot      # Install project-level skills

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage:
  $0 setup                              Install user-level skills and universal CLAUDE.md
  $0 <project-path> <stack> [stack...]  Install project-level skills for a tech stack

Supported stacks:
  java          Java language conventions
  spring-boot   Spring Boot conventions (also installs java, generation, and refactoring skills)
  react         React/TypeScript conventions (also installs react generation skills)
  kafka         Kafka conventions

Examples:
  $0 setup
  $0 ~/myproject java spring-boot react
EOF
  exit 1
}

# Copy a skill directory to a target skills directory
install_skill() {
  local skill_dir="$1"
  local target_dir="$2"
  local skill_name
  skill_name="$(basename "$skill_dir")"

  if [[ ! -d "$skill_dir" ]]; then
    echo "  [warn] Skill not found: $skill_dir" >&2
    return
  fi

  mkdir -p "$target_dir/$skill_name"
  cp -r "$skill_dir"/. "$target_dir/$skill_name/"
  echo "  + $skill_name"
}

# ── setup mode ────────────────────────────────────────────────────────────────

cmd_setup() {
  local user_claude_dir="$HOME/.claude"
  local user_skills_dir="$user_claude_dir/skills"
  local user_claude_md="$user_claude_dir/CLAUDE.md"

  echo "Setting up user-level Claude Code configuration..."
  mkdir -p "$user_skills_dir"

  # Install universal CLAUDE.md to user memory
  echo ""
  echo "Installing universal CLAUDE.md → $user_claude_md"
  if [[ -f "$user_claude_md" ]]; then
    echo "  [info] $user_claude_md already exists — appending universal layer"
    echo "" >> "$user_claude_md"
    echo "<!-- claude-docs universal layer -->" >> "$user_claude_md"
    cat "$SCRIPT_DIR/layers/base/universal.md" >> "$user_claude_md"
  else
    cp "$SCRIPT_DIR/layers/base/universal.md" "$user_claude_md"
    echo "  + CLAUDE.md"
  fi

  # Install user-level skills (analysis, workflows, promote)
  echo ""
  echo "Installing user-level skills → $user_skills_dir"

  for skill in "$SCRIPT_DIR/skills/analysis"/*/; do
    install_skill "$skill" "$user_skills_dir"
  done

  for skill in "$SCRIPT_DIR/skills/workflows"/*/; do
    install_skill "$skill" "$user_skills_dir"
  done

  install_skill "$SCRIPT_DIR/skills/promote" "$user_skills_dir"

  echo ""
  echo "Done. User-level skills installed to $user_skills_dir"
  echo "      Universal standards written to $user_claude_md"
}

# ── project mode ──────────────────────────────────────────────────────────────

cmd_project() {
  local project_path="$1"
  shift
  local stacks=("$@")

  if [[ ! -d "$project_path" ]]; then
    echo "Error: project path does not exist: $project_path" >&2
    exit 1
  fi

  local project_skills_dir="$project_path/.claude/skills"
  mkdir -p "$project_skills_dir"

  echo "Installing project-level skills → $project_skills_dir"
  echo ""

  local installed_java=false

  for stack in "${stacks[@]}"; do
    case "$stack" in
      java)
        echo "Stack: java"
        install_skill "$SCRIPT_DIR/skills/conventions/java" "$project_skills_dir"
        installed_java=true
        ;;

      spring-boot)
        echo "Stack: spring-boot"
        if [[ "$installed_java" == false ]]; then
          install_skill "$SCRIPT_DIR/skills/conventions/java" "$project_skills_dir"
          installed_java=true
        fi
        install_skill "$SCRIPT_DIR/skills/conventions/spring-boot" "$project_skills_dir"
        echo "  Generation skills:"
        install_skill "$SCRIPT_DIR/skills/generation/new-entity" "$project_skills_dir"
        install_skill "$SCRIPT_DIR/skills/generation/new-endpoint" "$project_skills_dir"
        install_skill "$SCRIPT_DIR/skills/generation/new-migration" "$project_skills_dir"
        echo "  Refactoring skills:"
        install_skill "$SCRIPT_DIR/skills/refactoring/extract-service" "$project_skills_dir"
        install_skill "$SCRIPT_DIR/skills/refactoring/add-validation" "$project_skills_dir"
        install_skill "$SCRIPT_DIR/skills/refactoring/add-tests" "$project_skills_dir"
        install_skill "$SCRIPT_DIR/skills/refactoring/optimise-query" "$project_skills_dir"
        ;;

      react)
        echo "Stack: react"
        install_skill "$SCRIPT_DIR/skills/conventions/react" "$project_skills_dir"
        echo "  Generation skills:"
        install_skill "$SCRIPT_DIR/skills/generation/new-react-page" "$project_skills_dir"
        install_skill "$SCRIPT_DIR/skills/generation/new-react-component" "$project_skills_dir"
        ;;

      kafka)
        echo "Stack: kafka"
        install_skill "$SCRIPT_DIR/skills/conventions/kafka" "$project_skills_dir"
        echo "  Generation skills:"
        install_skill "$SCRIPT_DIR/skills/generation/new-kafka-topic" "$project_skills_dir"
        ;;

      *)
        echo "  [warn] Unknown stack '$stack' — skipping" >&2
        ;;
    esac
    echo ""
  done

  echo "Done. Project skills installed to $project_skills_dir"
  echo ""
  echo "Next steps:"
  echo "  1. Copy templates/domain.md to your project and fill in the domain context"
  echo "  2. Add the filled domain.md content to your project's CLAUDE.md"
}

# ── entry point ───────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
  usage
fi

case "$1" in
  setup)
    cmd_setup
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    if [[ $# -lt 2 ]]; then
      echo "Error: project mode requires a project path and at least one stack" >&2
      usage
    fi
    cmd_project "$@"
    ;;
esac
