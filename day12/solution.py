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


def test_regionize_example_small():
    lines = example_small.splitlines()
    rows, cols = len(lines), len(lines[0])
    coords = set(product(range(cols), range(rows)))
    seen = set()
