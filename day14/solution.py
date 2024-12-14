from collections import Counter
from collections.abc import Iterable
from dataclasses import dataclass
from typing import Protocol, Literal
from functools import partial
from itertools import count


example = """
p=0,4 v=3,-3
p=6,3 v=-1,-3
p=10,3 v=-1,2
p=2,0 v=2,-1
p=0,0 v=1,3
p=3,0 v=-2,-2
p=7,6 v=-1,-3
p=3,0 v=-1,-2
p=9,3 v=2,3
p=7,3 v=-1,2
p=2,4 v=2,-3
p=9,5 v=-3,-3
""".strip()


class Pointlike(Protocol):
    x: int
    y: int


def quadrant(point: Pointlike, width: int, height: int) -> Literal[1, 2, 3, 4] | None:
    # x_boundary_bottom, y_boundary_bottom = width // 2, height // 2
    # x_boundary_top, y_boundary_top = x_boundary_bottom + 1, y_boundary_bottom + 1

    # to_left = point.x < x_boundary_bottom
    # to_right = x_boundary_top < point.x
    # to_top = point.y < y_boundary_bottom
    # to_bottom = y_boundary_top < point.y
    assert width % 2 == 1
    assert height % 2 == 1

    center_vert = width // 2
    center_horiz = height // 2
    if point.x == center_vert or point.y == center_horiz:
        return None

    if point.x < center_vert:
        return 1 if point.y < center_horiz else 2
    if point.x > center_vert:
        return 3 if point.y < center_horiz else 4

    return 1


def visualize(ps: Iterable[Pointlike], width: int, height: int) -> str:
    lines: list[list[int]] = [[0] * width for _ in range(height)]

    for p in ps:
        if lines[p.y][p.x] == ".":
            lines[p.y][p.x] = 1
        else:
            lines[p.y][p.x] += 1

    printable = [[str(i) if i else "." for i in line] for line in lines]

    return "\n".join(("".join(line) for line in printable))


@dataclass
class Robot:
    x: int
    y: int
    dx: int
    dy: int

    @classmethod
    def parse_line(cls, s: str):
        p_assign, v_assign = s.split(" ")
        p, coords = p_assign.split("=")
        v, velocity = v_assign.split("=")

        assert p == "p"
        assert v == "v"

        x_str, y_str = coords.split(",")
        dx_str, dy_str = velocity.split(",")

        return cls(x=int(x_str), y=int(y_str), dx=int(dx_str), dy=int(dy_str))

    @classmethod
    def parse_lines(cls, s: str):
        for line in s.splitlines():
            yield cls.parse_line(line)

    def advanced(self, width: int, height: int, n: int) -> "Robot":
        return Robot(
            x=(self.x + (self.dx * n)) % width,
            y=(self.y + (self.dy * n)) % height,
            dx=self.dx,
            dy=self.dy,
        )


if __name__ == "__main__":
    robots = tuple(Robot.parse_lines(example))
    print(visualize(robots, width=11, height=7), end="\n\n")
    advanced = [r.advanced(n=100, width=11, height=7) for r in robots]
    print(visualize(advanced, width=11, height=7), end="\n\n")
    quadrants = Counter(map(partial(quadrant, width=11, height=7), advanced))

    safety_factor = (
        quadrants.get(1, 0)
        * quadrants.get(2, 0)
        * quadrants.get(3, 0)
        * quadrants.get(4, 0)
    )

    print(
        f"Safety Factor = {safety_factor} ({quadrants.get(1) = } * {quadrants.get(2) = } * {quadrants.get(3) = } * {quadrants.get(4) = })"
    )

    with open("input") as f:
        robots = tuple(Robot.parse_lines(f.read()))
    advanced = [r.advanced(n=100, width=101, height=103) for r in robots]
    quadrants = Counter(map(partial(quadrant, width=101, height=103), advanced))
    safety_factor = (
        quadrants.get(1, 0)
        * quadrants.get(2, 0)
        * quadrants.get(3, 0)
        * quadrants.get(4, 0)
    )

    print(
        f"Safety Factor = {safety_factor} ({quadrants.get(1) = } * {quadrants.get(2) = } * {quadrants.get(3) = } * {quadrants.get(4) = })"
    )

    for n in count():
        advanced = [r.advanced(n=n, width=101, height=103) for r in robots]
        if "111111" in (visualized := visualize(advanced, width=101, height=103)):
            print(n)
            print(visualized)
            input()


def test_parse_line():
    assert Robot.parse_line("p=0,4 v=3,-3") == Robot(x=0, y=4, dx=3, dy=-3)


def test_parse_lines():
    assert list(Robot.parse_lines(example)) == [
        Robot(x=0, y=4, dx=3, dy=-3),
        Robot(x=6, y=3, dx=-1, dy=-3),
        Robot(x=10, y=3, dx=-1, dy=2),
        Robot(x=2, y=0, dx=2, dy=-1),
        Robot(x=0, y=0, dx=1, dy=3),
        Robot(x=3, y=0, dx=-2, dy=-2),
        Robot(x=7, y=6, dx=-1, dy=-3),
        Robot(x=3, y=0, dx=-1, dy=-2),
        Robot(x=9, y=3, dx=2, dy=3),
        Robot(x=7, y=3, dx=-1, dy=2),
        Robot(x=2, y=4, dx=2, dy=-3),
        Robot(x=9, y=5, dx=-3, dy=-3),
    ]


def test_example_single():
    robot = Robot.parse_line("p=2,4 v=2,-3")
    adv = partial(robot.advanced, width=11, height=7)

    assert adv(n=1) == Robot(x=4, y=1, dx=2, dy=-3)
    assert adv(n=2) == Robot(x=6, y=5, dx=2, dy=-3)
    assert adv(n=3) == Robot(x=8, y=2, dx=2, dy=-3)
    assert adv(n=4) == Robot(x=10, y=6, dx=2, dy=-3)
    assert adv(n=5) == Robot(x=1, y=3, dx=2, dy=-3)


def test_example_full():
    robots = Robot.parse_lines(example)
    advanced = [r.advanced(n=100, width=11, height=7) for r in robots]
