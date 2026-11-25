#!/usr/bin/env python3
"""
PreToolUse hook: Suggest Antigravity for research tasks.

Analyzes web search/fetch operations and suggests using Antigravity CLI
for comprehensive research with its larger context window.
"""

import json
import sys

# Keywords that suggest deep research would benefit from Antigravity
RESEARCH_INDICATORS = [
    "documentation",
    "best practice",
    "comparison",
    "library",
    "framework",
    "tutorial",
    "guide",
    "example",
    "pattern",
    "architecture",
    "migration",
    "upgrade",
    "breaking change",
    "api reference",
    "specification",
]

# Simple lookups that don't need Antigravity
SIMPLE_LOOKUP_PATTERNS = [
    "error message",
    "stack trace",
    "version",
    "release notes",
    "changelog",
]


def should_suggest_antigravity(query: str, url: str = "") -> tuple[bool, str]:
    """Determine if Antigravity should be suggested for this research."""
    query_lower = query.lower()
    url_lower = url.lower()
    combined = f"{query_lower} {url_lower}"

    # Skip simple lookups
    for pattern in SIMPLE_LOOKUP_PATTERNS:
        if pattern in combined:
            return False, ""

    # Check for research indicators
    for indicator in RESEARCH_INDICATORS:
        if indicator in combined:
            return True, f"Research involves '{indicator}'"

    # Long queries suggest complex research
    if len(query) > 100:
        return True, "Complex research query detected"

    return False, ""


def main():
    try:
        data = json.load(sys.stdin)
        tool_name = data.get("tool_name", "")
        tool_input = data.get("tool_input", {})

        # Get query/url based on tool type
        query = ""
        url = ""
        if tool_name == "WebSearch":
            query = tool_input.get("query", "")
        elif tool_name == "WebFetch":
            url = tool_input.get("url", "")
            query = tool_input.get("prompt", "")

        should_suggest, reason = should_suggest_antigravity(query, url)

        if should_suggest:
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "additionalContext": (
                        f"[Antigravity Research Suggestion] {reason}. "
                        "For comprehensive research, consider using Antigravity CLI (1M token context). "
                        "**Recommended**: Use Task tool with subagent_type='general-purpose' "
                        "to consult Antigravity and save results to .claude/docs/research/. "
                        "(Direct call OK for quick questions: `agy -p '...' 2>/dev/null`)"
                    )
                }
            }
            print(json.dumps(output))

        sys.exit(0)

    except Exception as e:
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
