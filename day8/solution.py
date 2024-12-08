# /// script
# dependencies = [
#   "pytest",
# ]
# ///
from __future__ import annotations
from dataclasses import dataclass
from functools import cached_property, cache, total_ordering
from collections import defaultdict
from itertools import combinations


import pytest
from pytest import param as prm


example = """
............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............
"""


@dataclass
class Cell:
    frequency: int | None

    # Start with the assumption that nothing's an antipode.
    is_antinode: bool = False

    def __str__(self) -> str:
        return (
            "#"
            if self.is_antinode
            else "."
            if self.frequency is None
            else chr(self.frequency)
        )

    @classmethod
    def from_str(cls: type[Cell], s: str) -> Cell:
        if len(s) != 1:
            raise ValueError("Expected a single char; got %s", str)
        return Cell(frequency=None if s == "." else ord(s))

    def __eq__(self, value: object, /) -> bool:
        return isinstance(value, Cell) and self.frequency == value.frequency


@total_ordering
@dataclass(frozen=True)
class Point:
    row: int
    col: int

    def __eq__(self, value: object, /) -> bool:
        return (
            isinstance(value, Point) and self.row == value.row and self.col == value.col
        )

    def __gt__(self, value: object, /) -> bool:
        if not isinstance(value, Point):
            raise TypeError
        return (self.row > value.row) or (self.col > value.col)


@dataclass
class Field:
    data: tuple[tuple[Cell, ...], ...]
    _marked: bool = False

    @classmethod
    def from_str(cls: type[Field], s: str) -> Field:
        return Field(
            data=tuple(
                tuple(Cell.from_str(c) for c in line) for line in s.splitlines() if line
            )
        )

    def __str__(self) -> str:
        out = []
        i = 0
        for row in self.data:
            i += 1
            for cell in row:
                out.append(str(cell))
            out.append("\n")
        # Remove final newline.
        return "".join(out[:-1])

    @cached_property
    def freq_map(self):
        freq_map = defaultdict(set)
        for row_idx, row in enumerate(self.data):
            for col_idx, cell in enumerate(row):
                if cell.frequency is not None:
                    freq_map[cell.frequency].add(Point(row=row_idx, col=col_idx))
        return {k: frozenset(v) for k, v in freq_map.items()}

    def antinode_count(self):
        self.mark_antinodes()
        count = 0
        for row in self.data:
            for cell in row:
                if cell.is_antinode:
                    count += 1
        return count

    def known_freqs(self):
        return frozenset(self.freq_map)

    def coords_with_freq(self, freq=int):
        return self.freq_map[freq]

    def mark_antinodes(self):
        if self._marked:
            return
        for k, v in self.freq_map.items():
            for p0, p1 in combinations(v, 2):
                greater, lesser = (p0, p1) if p0 > p1 else (p1, p0)
                row_diff = greater.row - lesser.row
                col_diff = greater.col - lesser.col

                antinode_lesser = Point(lesser.row - row_diff, lesser.col - col_diff)
                antinode_greater = Point(greater.row + row_diff, greater.col + col_diff)

                for antinode in (antinode_lesser, antinode_greater):
                    if antinode.row < 0 or antinode.col < 0:
                        continue
                    row = tuple()
                    try:
                        row = self.data[antinode.row]
                    except IndexError:
                        pass
                    try:
                        row[antinode.col].is_antinode = True
                    except IndexError:
                        pass
        self._marked = True


if __name__ == "__main__":
    with open("input") as f:
        i = f.read()
    field = Field.from_str(i)
    print(f"part 1: {field.antinode_count()}")


@pytest.mark.parametrize(
    "arg,expected",
    [
        prm(".", Cell(frequency=None)),
        prm("a", Cell(frequency=97)),
        prm("A", Cell(frequency=65)),
    ],
)
def test_from_str(arg: str, expected: Cell):
    assert expected == Cell.from_str(arg)


def test_example():
    f = Field.from_str(example)
    # assert str(f) == example.strip()

    for roi, row_outer in enumerate(f.data):
        for coi, cell_outer in enumerate(row_outer):
            for rii, row_inner in enumerate(f.data):
                for cii, cell_inner in enumerate(row_inner):
                    if roi != rii and coi != cii:
                        assert cell_outer is not cell_inner, (roi, coi, rii, cii)

    f.mark_antinodes()
    assert (
        str(f)
        == """
......#....#
...#....0...
....#0....#.
..#....0....
....0....#..
.#....#.....
...#........
#......#....
........A...
.........A..
..........#.
..........#.
    """.strip()
    )

    assert f.antinode_count() == 14

def test_part_1():
    with open("input") as f:
        i = f.read()
    field = Field.from_str(i)
    assert field.antinode_count() == 276
