from typing import Collection
from itertools import product, count, chain
from functools import cache, partial
import input_
import pytest

example = (
    (5, 4),
    (4, 2),
    (4, 5),
    (3, 0),
    (2, 1),
    (6, 3),
    (2, 4),
    (1, 5),
    (0, 6),
    (3, 3),
    (2, 6),
    (5, 1),
    (1, 2),
    (5, 5),
    (2, 5),
    (6, 5),
    (1, 4),
    (0, 4),
    (6, 4),
    (1, 1),
    (6, 1),
    (1, 0),
    (0, 5),
    (1, 6),
    (2, 0),
)

example_as_set = set(example)

example_after_12_ns = """
...#...
..#..#.
....#..
...#..#
..#..#.
.#..#..
#.#....
""".strip()


def test_example_visualize():
    assert visualize(example[:12], 7, 7) == example_after_12_ns


# def test_input_visualize():
#     assert visualize(input_.input_, 71, 71) == ""


def test_example_path():
    assert bad_a_star(example[:12], 7, 7) == 22


def test_part1_path():
    assert bad_a_star(input_.input_[:1024], 71, 71) == 506


def test_part2_path():
    with pytest.raises(ValueError):
        assert bad_a_star(input_.input_, 71, 71)


def test_part2_example():
    last_straw = None
    for i, input_len in enumerate(count(0)):
        if input_len > len(example) + 1:
            raise ValueError("never worked")
        ipt = example[:input_len]
        try:
            bad_a_star(ipt, 71, 71)
        except Exception:
            last_straw = ipt[-1]
            break
    assert last_straw is None


def test_part2():
    last_straw = None
    for i, input_len in enumerate(count(1025)):
        if input_len > len(input_.input_) + 1:
            raise ValueError("never worked")
        ipt = input_.input_[:input_len]
        if i % 100 == 0:
            print(f"iteration {i} ({len(ipt) = })")
        try:
            bad_a_star(ipt, 71, 71)
        except Exception:
            last_straw = ipt[-1]
            break
    assert last_straw is None


def visualize(coords: Collection[tuple[int, int]], width: int, height: int):
    coords = set(coords)
    lines = [["."] * width for _ in range(height)]
    for point in product(range(width), range(height)):
        if point in coords:
            lines[point[1]][point[0]] = "#"
    return "\n".join("".join(line) for line in lines)


@cache
def neighbors(point: tuple[int, int], width: int, height: int) -> set[tuple[int, int]]:
    return set(
        candidate
        for candidate in (
            (point[0] - 1, point[1]),
            (point[0], point[1] - 1),
            (point[0] + 1, point[1]),
            (point[0], point[1] + 1),
        )
        if (0 <= candidate[0] < width) and (0 <= candidate[1] < height)
    )


def bad_a_star(coords: Collection[tuple[int, int]], width: int, height: int):
    my_neighbors = partial(neighbors, width=width, height=height)
    coords_as_set = set(coords)
    points: set[tuple[int, int]] = {(0, 0)}
    seen: set[tuple[int, int]] = {(0, 0)}

    for i in count(1):
        if not points:
            raise ValueError
        new_neighbors = set(chain.from_iterable(my_neighbors(p) for p in points))
        new_neighbors -= coords_as_set
        new_neighbors -= seen
        if (width - 1, height - 1) in new_neighbors:
            return i
        points = new_neighbors
        seen |= new_neighbors
