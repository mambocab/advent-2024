# /// script
# dependencies = [
#   "pytest",
# ]
# ///
from __future__ import annotations
from dataclasses import dataclass


import pytest
from pytest import param as prm


example = "2333133121414131402"


class _Sentinel: ...


SENTINEL = _Sentinel()


@dataclass
class FS:
    metas: list[int | None]

    @classmethod
    def from_str(cls, s: str) -> "FS":
        metas: list[int | None] = []
        for i, c in enumerate(s):
            if c == "\n":
                continue
            file_id, rem = divmod(i, 2)
            metas.extend(
                ([None] if rem else [file_id]) * int(c),
            )
        return cls(metas=metas)

    def swap_blocks(self) -> bool:
        first_none_idx = self.metas.index(None)
        got = SENTINEL
        last_non_none_idx = None
        for last_non_none_idx in range(len(self.metas) - 1, 0, -1):
            if (got := self.metas[last_non_none_idx]) is not None:
                break
        if got is SENTINEL:
            raise ValueError

        assert not isinstance(got, _Sentinel)
        assert last_non_none_idx is not None

        if first_none_idx > last_non_none_idx:
            return False

        self.metas[first_none_idx] = got
        self.metas[last_non_none_idx] = None
        return True

    def compact(self) -> None:
        while self.swap_blocks():
            ...

    def checksum(self) -> int:
        result = 0
        for i, x in enumerate(self.metas):
            if x is not None:
                result += x * i
        return result

    def __str__(self) -> str:
        return "".join([str(x) if x is not None else "." for x in self.metas])


if __name__ == "__main__":
    with open("input") as f:
        i = f.read()
    fs = FS.from_str(i)
    print("compacting...")
    fs.compact()
    print(fs.checksum())


def test_trivial():
    fs = FS.from_str("12345")
    assert fs.metas == [0] + [None] * 2 + [1] * 3 + [None] * 4 + [2] * 5


def test_example():
    fs = FS.from_str("2333133121414131402")

    # fmt: off
    assert fs.metas == [
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
