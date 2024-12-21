from __future__ import annotations
from dataclasses import dataclass
from enum import Enum, auto
from functools import cache
import pytest

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
    NO = auto()
    STARTED = auto()
    DONE = auto()


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
        return "".join(builder[:-1])


@pytest.fixture
def parsed_example() -> Map:
    return Map.from_str(example)


@pytest.fixture
def read_input() -> str:
    with open("input") as f:
        return f.read().strip()


@pytest.fixture
def parsed_input(read_input: str) -> Map:
    return Map.from_str(read_input)


class TestParsing:
    def test_parsing(self, parsed_example: Map):
        assert repr(parsed_example) == example

    def test_parsed_input(self, parsed_input: Map, read_input: str):
        assert repr(parsed_input) == read_input


@cache
def at_point(point: Point, grid: Grid) -> Square | None:
    try:
        return grid[point[1]][point[0]]
    except IndexError:
        return None


@cache
def cheating_state(path: Path, grid: Grid) -> CheatingState:
    if len(path) == 0:
        return CheatingState.NO

    currently_cheating = False
    for point in path:
        floor = at_point(point=point, grid=grid)
        if floor == Square.WALL:
            if currently_cheating:
                return CheatingState.DONE
            currently_cheating = True
        elif floor == Square.TRACK:
            if currently_cheating:
                return CheatingState.DONE

    return CheatingState.STARTED if currently_cheating else CheatingState.NO


class TestCheatingState:
    def test_not_cheating_trivial(self, parsed_example: Map):
        assert cheating_state(tuple(), parsed_example.grid) == CheatingState.NO

    def test_not_cheating(self, parsed_example: Map):
        #       start,  ^     , ^     , >     , >
        path = ((1, 3), (1, 2), (1, 1), (2, 1), (3, 1))
        assert cheating_state(path[:1], parsed_example.grid) == CheatingState.NO
        assert cheating_state(path[:2], parsed_example.grid) == CheatingState.NO
        assert cheating_state(path[:3], parsed_example.grid) == CheatingState.NO
        assert cheating_state(path, parsed_example.grid) == CheatingState.NO

    def test_mid_cheat(self, parsed_example: Map):
        #       start,  ^     , >
        path = ((1, 3), (1, 2), (2, 2))
        assert cheating_state(path[:1], parsed_example.grid) == CheatingState.NO
        assert cheating_state(path[:2], parsed_example.grid) == CheatingState.NO
        assert cheating_state(path, parsed_example.grid) == CheatingState.STARTED

    def test_already_cheated_single_step(self, parsed_example: Map):
        #       start,  >     , >
        path = ((1, 3), (2, 3), (3, 3))
        assert cheating_state(path[:1], parsed_example.grid) == CheatingState.NO
        assert cheating_state(path[:2], parsed_example.grid) == CheatingState.STARTED
        assert cheating_state(path, parsed_example.grid) == CheatingState.DONE

    def test_already_cheated_two_steps(self, parsed_example: Map):
        #       start,  >     , ^     , ^
        path = ((1, 3), (2, 3), (2, 2), (2, 1))
        assert cheating_state(path[:1], parsed_example.grid) == CheatingState.NO
        assert cheating_state(path[:2], parsed_example.grid) == CheatingState.STARTED
        assert cheating_state(path[:3], parsed_example.grid) == CheatingState.DONE
        assert cheating_state(path, parsed_example.grid) == CheatingState.DONE


def neighbors(point: Point, grid: Grid, already_cheated: bool) -> set[Point]:
    candidates = (
        (point[0] - 1, point[1]),
        (point[0], point[1] - 1),
        (point[0] + 1, point[1]),
        (point[0], point[1] + 1),
    )

    def valid(s: Square | None) -> bool:
        if already_cheated:
            return s == Square.TRACK
        return s is not None

    return set(
        candidate for candidate in candidates if valid(at_point(candidate, grid))
    )


def find_paths(m: Map): ...


def test_example_counts(parsed_example): ...
