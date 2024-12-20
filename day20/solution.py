from __future__ import annotations
from dataclasses import dataclass
from enum import Enum, auto
from functools import cache
from typing import assert_never

example = """
###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############
""".strip()

type Row = int
type Col = int
type Point = tuple[Col, Row]
type Grid = tuple[tuple[Square, ...], ...]
type Path = tuple[Point, ...]


class Square(Enum):
    TRACK = auto()
    WALL = auto()


class CheatingState(Enum):
    NOT_STARTED = auto()
    STARTED = auto()
    DONE = auto()


@cache
def at_point(point, grid) -> Square:
    return grid[point[1]][point[0]]


@dataclass
class Map:
    start: Point
    end: Point
    grid: Grid

    @classmethod
    def from_str(cls: type[Map], s: str) -> Map:
        start: Point | None = None
        end: Point | None = None
        grid_builder: list[tuple[Square, ...]] = []

        for row, line in enumerate(s.splitlines()):
            line_builder = []
            for col, char in enumerate(line):
                if char == "#":
                    line_builder.append(Square.WALL)
                elif char == ".":
                    line_builder.append(Square.TRACK)
                elif char == "S":
                    start = (col, row)
                    line_builder.append(Square.TRACK)
                elif char == "E":
                    end = (col, row)
                    line_builder.append(Square.TRACK)
                else:
                    raise ValueError("unable to process char %s", char)

            grid_builder.append(tuple(line_builder))

        assert start
        assert end
        return cls(
            start=start,
            end=end,
            grid=tuple(grid_builder),
        )

    def __repr__(self) -> str:
        builder = []
        for row_idx, row in enumerate(self.grid):
            for col_idx, char in enumerate(row):
                if (col_idx, row_idx) == self.start:
                    builder.append("S")
                elif (col_idx, row_idx) == self.end:
                    builder.append("E")
                elif char == Square.WALL:
                    builder.append("#")
                elif char == Square.TRACK:
                    builder.append(".")
            builder.append("\n")
        return ''.join(builder[:-1])

def test_parsing():
    assert repr(Map.from_str(example)) == example

@cache
def cheating_state(path: Path, grid: Grid) -> CheatingState:
    if len(path) == 0:
        return CheatingState.NOT_STARTED

    currently_cheating = False
    for point in path:
        if grid[point[1]][point[0]] == Square.WALL:
            if currently_cheating:
                return CheatingState.DONE
            currently_cheating = True

    return CheatingState.NOT_STARTED
