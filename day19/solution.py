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
def possible(towels: frozenset[str], design: str) -> int:
    if design == "":
        # We've bottomed out and consumed the whole design. Good to go.
        return 1

    result = 0
    for towel in towels:
        if design == towel:
            # We've bottomed out and consumed the whole design. Good to go.
            result += 1
        elif design.startswith(towel):
            result += possible(towels, design[len(towel) :])

    return result


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
    with open("input") as f:
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
    ((frozenset(("rg",)), "rg", 1),),
)
def test_possible_trivial(towels: frozenset[str], design: str, want: bool):
    assert possible(towels, design) is want


@pytest.mark.parametrize(
    "args, want",
    (
        (
            ("brwrr", 2),
            ("bggr", 1),
            ("gbbr", 4),
            ("rrbgbr", 6),
            ("ubwu", 0),
            ("bwurrg", 1),
            ("brgr", 2),
            ("bbrgwb", 0),
        )
    ),
)
def test_possible_example(parsed_example: Parsed, args: str, want: bool):
    assert possible(parsed_example.towels, args) == want


def test_calculate_result(parsed_input: Parsed):
    part1 = part2 = 0
    for design in parsed_input.designs:
        result = possible(parsed_input.towels, design)
        part1 += bool(result)
        part2 += result
    assert part1 == 363
    assert part2 == 642535800868438
