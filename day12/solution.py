from functools import cache
from itertools import product

example_small = """
AAAA
BBCD
BBCC
EEEC
""".strip()

example_large = """
RRRRIICCFF
RRRRIICCCF
VVRRRCCFFF
VVRCCCJFFF
VVVVCJJCFE
VVIVCCJJEE
VVIIICJJEE
MIIIIIJJEE
MIIISIJEEE
MMMISSJEEE
""".strip()

type Grid = tuple[str, ...]


@cache
def get_from_grid(point, grid):
    try:
        grid[point[1]][point[0]]
    except IndexError:
        return None

@cache
def neighbors(point, grid: Grid):
    return set(
        candidate
        for candidate in (
            (point[0] - 1, point[1]),
            (point[0], point[1] - 1),
            (point[0] + 1, point[1]),
            (point[0], point[1] + 1),
        )
        if get_from_grid(candidate, grid) is not None
    )

def test_regionize_example_small():
    lines: Grid = tuple(example_small.splitlines())
    rows, cols = len(lines), len(lines[0])
    coords = set(product(range(cols), range(rows)))
    seen = set()
    while seen != coords:
        for point in coords - seen:
            if point in seen:
                continue
            
            seen.add(point)
            at_point = get_from_grid(point(lines))
            for neighbor in neighbors(point, lines):
                if ...
