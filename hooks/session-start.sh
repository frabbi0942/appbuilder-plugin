#!/usr/bin/env bash
# AppBuilder — Session Start Hook
# Injects context about registered projects

REGISTRY_FILE="$HOME/.appbuilder/registry.json"

if [ -f "$REGISTRY_FILE" ]; then
  PROJECT_COUNT=$(node -e "const r=JSON.parse(require('fs').readFileSync('$REGISTRY_FILE','utf8'));console.log(Object.keys(r.projects).length)" 2>/dev/null || echo "0")

  if [ "$PROJECT_COUNT" -gt 0 ]; then
    echo "AppBuilder: $PROJECT_COUNT project(s) registered. Use /appbuilder-build to create a new app or /appbuilder-iterate to modify an existing one."
    echo ""
    echo "Commands: /appbuilder-build, /appbuilder-iterate, /appbuilder-preview, /appbuilder-deploy-config"
  else
    echo "AppBuilder: No projects yet. Use /appbuilder-build \"your app idea\" to create one."
  fi
else
  echo "AppBuilder: Ready. Use /appbuilder-build \"your app idea\" to create your first app."
fi
