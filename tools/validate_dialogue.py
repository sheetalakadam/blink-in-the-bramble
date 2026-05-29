#!/usr/bin/env python3
"""Validate all dialogue JSON files for structural correctness."""

import json
import os
import sys

DIALOGUE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "dialogue")
VALID_SPEAKERS = {"Zi", "Caelan", "Suri", "Rynn", "Lex", "Vyn", "Narrator", "Guard", "Soldier"}
FAILED = 0


def fail(file, msg):
    global FAILED
    FAILED += 1
    print(f"FAIL [{file}]: {msg}")


def validate_file(filepath):
    filename = os.path.basename(filepath)

    with open(filepath) as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            fail(filename, f"Invalid JSON: {e}")
            return

    # Must have id and start_node
    if "id" not in data:
        fail(filename, "Missing 'id' field")
    if "start_node" not in data:
        fail(filename, "Missing 'start_node' field")
    if "nodes" not in data:
        fail(filename, "Missing 'nodes' field")
        return

    nodes = data["nodes"]
    start = data.get("start_node", "")

    if start and start not in nodes:
        fail(filename, f"start_node '{start}' not found in nodes")

    # Validate each node
    for node_name, node in nodes.items():
        lines = node.get("lines", [])
        if not lines:
            fail(filename, f"Node '{node_name}' has no lines")

        for i, line in enumerate(lines):
            if "speaker" not in line:
                fail(filename, f"Node '{node_name}' line {i}: missing 'speaker'")
            if "text" not in line:
                fail(filename, f"Node '{node_name}' line {i}: missing 'text'")

            # Check choices format consistency
            if "choices" in line:
                for j, choice in enumerate(line["choices"]):
                    if "text" not in choice and "label" not in choice:
                        fail(filename, f"Node '{node_name}' line {i} choice {j}: missing 'text' or 'label'")
                    if "next_node" not in choice and "next" not in choice:
                        fail(filename, f"Node '{node_name}' line {i} choice {j}: missing 'next_node' or 'next'")

                    # Validate choice targets exist
                    target = choice.get("next_node") or choice.get("next", "")
                    if target and target not in nodes:
                        fail(filename, f"Node '{node_name}' choice target '{target}' not found in nodes")

        # Validate next_node references
        next_node = node.get("next_node", "")
        if next_node and next_node not in nodes:
            fail(filename, f"Node '{node_name}' next_node '{next_node}' not found in nodes")


def main():
    global FAILED

    if not os.path.isdir(DIALOGUE_DIR):
        print(f"Dialogue directory not found: {DIALOGUE_DIR}")
        sys.exit(1)

    files = sorted(f for f in os.listdir(DIALOGUE_DIR) if f.endswith(".json"))
    print(f"Validating {len(files)} dialogue files...")

    for filename in files:
        filepath = os.path.join(DIALOGUE_DIR, filename)
        validate_file(filepath)

    if FAILED > 0:
        print(f"\n{FAILED} issues found!")
        sys.exit(1)
    else:
        print(f"\nAll {len(files)} dialogue files are valid.")
        sys.exit(0)


if __name__ == "__main__":
    main()
