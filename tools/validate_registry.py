#!/usr/bin/env python3
"""Validate provisional MCL assigned-number registries and common-header vectors."""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def pack_header(major: int, category: int, opcode: int, priority: int, extension_present: int) -> bytes:
    if not 0 <= major < 16: raise ValueError("major")
    if not 0 <= category < 16: raise ValueError("category")
    if not 0 <= opcode < 32: raise ValueError("opcode")
    if not 0 <= priority < 4: raise ValueError("priority")
    if extension_present not in (0, 1): raise ValueError("extension_present")
    word = (major << 12) | (category << 8) | (opcode << 3) | (priority << 1) | extension_present
    return word.to_bytes(2, "big")


def unpack_header(data: bytes):
    if len(data) != 2: raise ValueError("common header must be exactly two bytes")
    word = int.from_bytes(data, "big")
    return {
        "major": (word >> 12) & 0xF,
        "category": (word >> 8) & 0xF,
        "opcode": (word >> 3) & 0x1F,
        "priority": (word >> 1) & 0x3,
        "extension_present": word & 0x1,
    }


def validate_registry(reg):
    h = reg["wire_header_model"]
    width = h["major_version_bits"] + h["category_bits"] + h["opcode_bits"] + h["priority_bits"] + h["extension_present_bits"]
    assert width == h["total_bits"] == 16

    category_codes = [c["code"] for c in reg["categories"]]
    assert len(category_codes) == len(set(category_codes)) == 16
    assert sorted(category_codes) == list(range(16))

    semantic_names = []
    for category in reg["categories"]:
        assert 0 <= category["code"] < 16
        opcodes = [o["code"] for o in category["opcodes"]]
        assert len(opcodes) == len(set(opcodes))
        assert all(0 <= op < 32 for op in opcodes)
        semantic_names.extend(o["name"] for o in category["opcodes"])

    assert len(semantic_names) == len(set(semantic_names))
    assert len(semantic_names) == 20
    return semantic_names


def validate_vectors(reg, vectors):
    by_name = {}
    for category in reg["categories"]:
        for opcode in category["opcodes"]:
            by_name[opcode["name"]] = (category["code"], opcode["code"])

    assert len(vectors["vectors"]) == len(by_name)
    for vector in vectors["vectors"]:
        name = vector["semantic"]
        assert name in by_name
        category, opcode = by_name[name]
        assert vector["category"] == category
        assert vector["opcode"] == opcode
        encoded = bytes.fromhex(vector["header_hex"])
        decoded = unpack_header(encoded)
        assert decoded["major"] == 0
        assert decoded["category"] == category
        assert decoded["opcode"] == opcode
        assert decoded["extension_present"] == 0


def main():
    reg = load(ROOT / "registries" / "semantic-codes-v0.2.json")
    vectors = load(ROOT / "conformance" / "header-v0.2-vectors.json")
    names = validate_registry(reg)
    validate_vectors(reg, vectors)

    count = 0
    for major in range(16):
        for category in range(16):
            for opcode in range(32):
                for priority in range(4):
                    for extension_present in range(2):
                        raw = pack_header(major, category, opcode, priority, extension_present)
                        got = unpack_header(raw)
                        assert got == {
                            "major": major,
                            "category": category,
                            "opcode": opcode,
                            "priority": priority,
                            "extension_present": extension_present,
                        }
                        count += 1

    print(f"registry semantic assignments: {len(names)}")
    print(f"header states round-tripped: {count}")
    print("OK")


if __name__ == "__main__":
    main()
