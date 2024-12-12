# /// script
# dependencies = [ "pytest" ]
# ///
from __future__ import annotations
from collections.abc import Collection
from dataclasses import dataclass
import pytest
from itertools import chain
from functools import cache

example = """125 17"""

input_ = "1750884 193 866395 7 1158 31 35216 0"


@dataclass
class Stone:
    value: str

    def blink(self) -> tuple[Stone] | tuple[Stone, Stone]:
        if self.value == "0":
            return (Stone("1"),)
        if len(self.value) % 2 == 0:
            left_raw, right_raw = halves(self.value)
            return Stone(str(int(left_raw))), Stone(str(int(right_raw)))
        return (Stone(str(int(self.value) * 2024)),)

    def __hash__(self) -> int:
        return hash(self.value + "Stone")


def blink(stones: Collection[Stone]):
    return tuple(chain.from_iterable(s.blink() for s in stones))


@cache
def count_after_n_blinks(stone: Stone, n: int):
    if n == 1:
        return len(stone.blink())
    return sum(count_after_n_blinks(s, n - 1) for s in stone.blink())


def test_count():
    assert (
        count_after_n_blinks(Stone("125"), 6) + count_after_n_blinks(Stone("17"), 6)
        == 22
    )
    assert (
        count_after_n_blinks(Stone("125"), 25) + count_after_n_blinks(Stone("17"), 25)
        == 55312
    )


@pytest.mark.parametrize(
    "arg, want",
    [
        (
            (Stone("125"), Stone("17")),
            (Stone("253000"), Stone("1"), Stone("7")),
        ),
        (
            (Stone("253000"), Stone("1"), Stone("7")),
            (Stone("253"), Stone("0"), Stone("2024"), Stone("14168")),
        ),
        (
            (Stone("253"), Stone("0"), Stone("2024"), Stone("14168")),
            (Stone("512072"), Stone("1"), Stone("20"), Stone("24"), Stone("28676032")),
        ),
    ],
)
def test_blinks(arg, want):
    assert blink(arg) == want


@pytest.mark.parametrize(
    "arg, want",
    [
        (Stone("0"), (Stone("1"),)),
        (Stone("1234"), (Stone("12"), Stone("34"))),
        (Stone("1000"), (Stone("10"), Stone("0"))),
        (Stone("100"), (Stone("202400"),)),
    ],
)
def test_blink(arg, want):
    assert arg.blink() == want


def halves(s: str) -> tuple[str, str]:
    if len(s) % 2 != 0:
        raise ValueError()
    return s[: len(s) // 2], s[len(s) // 2 :]


def test_halves():
    assert ("12", "34") == halves("1234")


def test_halves_err():
    with pytest.raises(ValueError):
        halves("012")

def test_part_1():
    stones = tuple(Stone(v) for v in input_.split())
    assert sum(count_after_n_blinks(s, 25) for s in stones) == 231278


if __name__ == "__main__":
    # Part 1
    stones = tuple(Stone(v) for v in input_.split())
    print(sum(count_after_n_blinks(s, 25) for s in stones))
