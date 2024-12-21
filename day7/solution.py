from dataclasses import dataclass
from typing import Self
import pytest
from functools import cache

example = """
190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20
""".strip()


@cache
def _possible(test_value: int, operands: tuple[int, ...]) -> bool:
    # Did we bottom out?
    if not operands:
        return True
    # Did we calculate the number?
    if len(operands) == 1:
        return operands[0] == test_value

    # Otherwise, recurse.
    front = operands[:-1]
    children = [Equation(test_value - operands[-1], front)]
    divresult, rem = divmod(test_value, operands[-1])
    if rem == 0:
        children.append(Equation(test_value=divresult, operands=front))
    for child in children:
        if child.possible:
            return True
    return False


@dataclass(frozen=True)
class Equation:
    test_value: int
    operands: tuple[int, ...]

    @classmethod
    def from_str(cls: type[Self], s: str) -> Self:
        s = s.strip()
        test_value = int((split := s.split(":"))[0])
        return cls(test_value=test_value, operands=tuple(map(int, split[1].split())))

    @property
    def possible(self) -> bool:
        return _possible(self.test_value, self.operands)


@pytest.fixture
def parsed_example() -> tuple[Equation, ...]:
    return tuple(Equation.from_str(line) for line in example.splitlines())


def test_parse_example(parsed_example):
    assert parsed_example == (
        Equation(test_value=190, operands=(10, 19)),
        Equation(test_value=3267, operands=(81, 40, 27)),
        Equation(test_value=83, operands=(17, 5)),
        Equation(test_value=156, operands=(15, 6)),
        Equation(test_value=7290, operands=(6, 8, 6, 15)),
        Equation(test_value=161011, operands=(16, 10, 13)),
        Equation(test_value=192, operands=(17, 8, 14)),
        Equation(test_value=21037, operands=(9, 7, 18, 13)),
        Equation(test_value=292, operands=(11, 6, 16, 20)),
    )


@pytest.mark.parametrize(
    "e, want",
    (
        (Equation(test_value=190, operands=(10, 19)), True),
        (Equation(test_value=3267, operands=(81, 40, 27)), True),
        (Equation(test_value=83, operands=(17, 5)), False),
        (Equation(test_value=156, operands=(15, 6)), False),
        (Equation(test_value=7290, operands=(6, 8, 6, 15)), False),
        (Equation(test_value=161011, operands=(16, 10, 13)), False),
        (Equation(test_value=192, operands=(17, 8, 14)), False),
        (Equation(test_value=21037, operands=(9, 7, 18, 13)), False),
        (Equation(test_value=292, operands=(11, 6, 16, 20)), True),
    ),
)
def test_example_possible(e: Equation, want: bool):
    assert e.possible is want


def test_part_1_example(parsed_example):
    assert sum(e.test_value for e in parsed_example if e.possible) == 3749


@pytest.fixture
def read_input():
    with open("input") as f:
        return f.read().strip()


@pytest.fixture
def parsed_input(read_input):
    return tuple(Equation.from_str(line) for line in read_input.splitlines())


def test_part_1(parsed_input):
    assert sum(e.test_value for e in parsed_input if e.possible) == 12940396350192
