#!/usr/bin/env python3
"""Shared timed-sequence loading for PR2 Flash/OpenFL drivers."""

import json


def load_sequence(script_path, *, normalize_hold=False, allow_query=True):
    with open(script_path) as file:
        data = json.load(file)

    if isinstance(data, list):
        query = common_step_query(data)
        raw_steps = data
    elif isinstance(data, dict):
        query = data.get("query", "")
        raw_steps = data.get("steps")
        if raw_steps is None:
            raise SystemExit(f"Sequence object must include steps: {script_path}")
        step_query = common_step_query(raw_steps)
        if query and step_query and query != step_query:
            raise SystemExit("Sequence query must be top-level when steps need different query strings.")
        query = query or step_query
    else:
        raise SystemExit(f"Sequence must be a JSON object or list: {script_path}")

    if query and not allow_query:
        raise SystemExit(f"Flash sequences cannot use query strings: {script_path}")

    return query, normalize_sequence_steps(raw_steps, normalize_hold=normalize_hold)


def common_step_query(steps):
    queries = {
        step.get("query", "")
        for step in steps
        if step.get("query", "") and step.get("action") != "navigate"
    }
    if len(queries) > 1:
        raise SystemExit("Sequence can only use one query string per browser session.")
    return next(iter(queries), "")


def normalize_sequence_steps(raw_steps, *, normalize_hold=False):
    if not isinstance(raw_steps, list):
        raise SystemExit("Sequence steps must be a list.")

    normalized = []
    order = 0
    for step in raw_steps:
        if not isinstance(step, dict):
            raise SystemExit(f"Sequence step must be an object: {step}")
        if "time" not in step or "action" not in step:
            raise SystemExit(f"Sequence step requires time and action: {step}")
        step_time = parse_non_negative_float(step["time"], "time")
        action = step["action"]
        if normalize_hold and action == "hold":
            seconds = parse_non_negative_float(step.get("seconds"), "seconds")
            key = require_field(step, "key")
            normalized.append({"time": step_time, "action": "keyDown", "key": key, "_order": order})
            order += 1
            normalized.append({"time": step_time + seconds, "action": "keyUp", "key": key, "_order": order})
        else:
            item = dict(step)
            item["time"] = step_time
            item["_order"] = order
            normalized.append(item)
        order += 1
    return sorted(normalized, key=lambda step: (step["time"], step["_order"]))


def require_field(step, field):
    value = step.get(field)
    if value is None or value == "":
        raise SystemExit(f"Sequence {step.get('action')} step requires {field}: {step}")
    return value


def parse_non_negative_float(value, label):
    try:
        parsed = float(value)
    except (TypeError, ValueError):
        raise SystemExit(f"Invalid sequence {label}: {value}")
    if parsed < 0:
        raise SystemExit(f"Sequence {label} must be non-negative: {value}")
    return parsed
