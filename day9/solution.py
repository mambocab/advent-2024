# /// script
# dependencies = [
#   "pytest",
# ]
# ///
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum, auto


example = "2333133121414131402"


class _Sentinel: ...


SENTINEL = _Sentinel()


class BlockType(Enum):
    FILE = auto()
    EMPTY = auto()


@dataclass
class Block:
    length: int
    type_: BlockType


@dataclass
class FS:
    files: list[Block]

    @classmethod
    def from_str(cls, s: str) -> "FS":
        files = []
        for i, c in enumerate(s):
            if c == "\n":
                continue
            files.append(
                Block(
                    length=int(c),
                    type_=BlockType.EMPTY if i % 2 == 0 else BlockType.FILE,
                )
            )
        return cls(files=list(files))

    def compact(self) -> None:


    def checksum(self) -> int:
        result = 0
        for i, x in enumerate(self.files):
            if x is not None:
                result += x * i
        return result

    def __str__(self) -> str:
        return "".join([str(x) if x is not None else "." for x in self.files])


if __name__ == "__main__":
    with open("input") as f:
        i = f.read()
    fs = FS.from_str(i)
    print("compacting...")
    fs.compact()
    print(fs.checksum())


def test_trivial():
    fs = FS.from_str("12345")
    assert fs.files == [0] + [None] * 2 + [1] * 3 + [None] * 4 + [2] * 5


def test_example():
    fs = FS.from_str("2333133121414131402")

    # fmt: off
    assert fs.files == [
        0, 0, None, None, None,
        1, 1, 1, None, None, None,
        2, None, None, None,
        3, 3, 3, None,
        4, 4, None,
        5, 5, 5, 5, None,
        6, 6, 6, 6, None,
        7, 7, 7, None,
        8, 8, 8, 8,
        9, 9,
    ]
    # fmt: on

    fs.compact()

    assert str(fs) == "0099811188827773336446555566.............."
    assert fs.checksum() == 1928


# Skipping: slow.
# def test_part1():
#     with open("input") as f:
#         i = f.read()
#     fs = FS.from_str(i)
#     print("compacting...")
#     fs.compact()
#     assert fs.checksum() == 6360094256423
