# /// script
# dependencies = []
# ///
from __future__ import annotations
from collections.abc import Iterable
from dataclasses import dataclass

example = """
89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732
"""


class Cell:
    value: int

    north: Cell | None = None
    east: Cell | None = None
    south: Cell | None = None
    west: Cell | None = None

    def __init__(self, value: int) -> None:
        self.value = value

    def set_east(self, other: Cell) -> None:
        self.east = other
        other.west = self

    def set_west(self, other: Cell) -> None:
        other.set_east(self)

    def set_south(self, other: Cell) -> None:
        self.south = other
        other.north = self

    def __str__(self) -> str:
        return str(self.value)

    @property
    def is_trailhead(self) -> bool:
        return self.value == 0

    @property
    def is_peak(self) -> bool:
        return self.value == 9

    @property
    def neighbors(self) -> Iterable[Cell]:
        if self.north:
            yield self.north
        if self.east:
            yield self.east
        if self.south:
            yield self.south
        if self.west:
            yield self.west

    def step(self) -> list[Cell]:
        result = []
        step_up = self.value + 1
        for neighbor in self.neighbors:
            if neighbor.value == step_up:
                result.append(neighbor)
        return result
        


@dataclass
class Map:
    _cells: tuple[tuple[Cell, ...], ...]

    @classmethod
    def from_str(cls, s: str) -> Map:
        cells: list[list[Cell]] = []
        for line_idx, line in enumerate(s.splitlines()):
            cells.append([])
            assert len(cells) - 1 == line_idx

            for char_idx, char in enumerate(line):
                cells[line_idx].append(Cell(int(char)))
                if char_idx > 0:
                    cells[line_idx][char_idx - 1].set_east(cells[line_idx][char_idx])

            if line_idx > 0:
                for north, south in zip(cells[line_idx - 1], cells[line_idx]):
                    north.set_south(south)

        return Map(_cells=tuple(tuple(row) for row in cells))

    @property
    def cells(self) -> Iterable[Cell]:
        for row in self._cells:
            for cell in row:
                yield cell

    @property
    def trailheads(self) -> Iterable[Cell]:
        yield from (c for c in self.cells if c.is_trailhead)


    def walk(self):
        current = list(self.trailheads)
        peaks = []
        while current:
            next_ = []
            for c in current:
                next_.extend(c.step())
            peaks.extend([c for c in next_ if c.is_peak])
            current = [c for c in next_ if not c.is_peak]
        return peaks


if __name__ == "__main__":
    m = Map.from_str(example)
    peaks = m.walk()
    print(len(peaks))


