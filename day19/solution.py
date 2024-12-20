from dataclasses import dataclass
import pytest
from functools import cache

example = """
r, wr, b, g, bwu, rb, gb, br

brwrr
bggr
gbbr
rrbgbr
ubwu
bwurrg
brgr
bbrgwb
""".strip()


@dataclass
class Parsed:
    towels: frozenset[str]
    designs: frozenset[str]


@cache
def possible(towels: frozenset[str], design: str) -> bool:
    if design == "":
        # We've bottomed out and consumed the whole design. Good to go.
        return True

    for towel in towels:
        if design == towel:
            # We've bottomed out and consumed the whole design. Good to go.
            return True
        if design.startswith(towel):
            if possible(towels, design[len(towel) :]):
                return True

    return False


def parse(s: str):
    lines = s.splitlines()
    return Parsed(
        towels=frozenset(towel.strip() for towel in lines[0].split(",")),
        designs=frozenset(line for line in lines[1:] if line),
    )


@pytest.fixture
def parsed_example():
    return parse(example)

@pytest.fixture
def parsed_input():
    with open('input') as f:
        return parse(f.read())


def test_parsed(parsed_example):
    assert parsed_example == Parsed(
        towels=frozenset(("wr", "g", "rb", "gb", "b", "br", "bwu", "r")),
        designs=frozenset(
            ("bbrgwb", "brwrr", "bggr", "rrbgbr", "bwurrg", "ubwu", "gbbr", "brgr")
        ),
    )


@pytest.mark.parametrize(
    "towels, design, want",
    ((frozenset(("rg",)), "rg", True),),
)
def test_possible_trivial(towels: frozenset[str], design: str, want: bool):
    assert possible(towels, design) is want


@pytest.mark.parametrize(
    "args, want",
    (
        (
            ("brwrr", True),
            ("bggr", True),
            ("gbbr", True),
            ("rrbgbr", True),
            ("ubwu", False),
            ("bwurrg", True),
            ("brgr", True),
            ("bbrgwb", False),
        )
    ),
)
def test_possible_example(parsed_example: Parsed, args: str, want: bool):
    assert possible(parsed_example.towels, args) is want

def test_part1(parsed_input: Parsed):
    c = 0
    for design in parsed_input.designs:
        c += bool(possible(parsed_input.towels, design))
    assert c == 363
