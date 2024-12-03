// File structure bitten from https://kristoff.it/blog/advent-of-code-zig/
const std = @import("std");
const input = @embedFile("input");
const example = @embedFile("example");

pub fn main() !void {
    const v = input;

    var stdout_bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer {
        // For this simple case we don't care about handling this class of error.
        // Ignore it so we can use defer.
        _ = stdout_bw.flush() catch {};
    }
    var stdout = stdout_bw.writer();
    const counts = try countSafeLines(v);
    try stdout.print("{any}\n", .{counts});
    try stdout.print("{d} safe for part 1, {d} safe for part 2\n", .{ counts[0], counts[1] });
}

pub fn countSafeLines(in: []const u8) ![2]usize {
    var safe_line_counts: [2]usize = .{ 0, 0 };
    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    var parsedLine: [1024]usize = undefined;
    while (lines.next()) |line| {
        var idx: usize = 0;
        var ints = std.mem.tokenizeScalar(u8, line, ' ');
        while (ints.next()) |iAsString| {
            parsedLine[idx] = try std.fmt.parseInt(usize, iAsString, 10);
            idx += 1;
        }

        const safe = isSafe(parsedLine[0..idx]);
        switch (safe) {
            SafeFor.part_one => {
                safe_line_counts[0] += 1;
            },
            SafeFor.part_two => {
                safe_line_counts[1] += 1;
            },
            SafeFor.never => {
                // noop
            },
        }
    }
    return .{ safe_line_counts[0], safe_line_counts[0] + safe_line_counts[1] };
}

test "example" {
    try std.testing.expectEqual(.{ 2, 4 }, (try countSafeLines(example)));
}

const SafeFor = enum { part_one, part_two, never };

const Direction = enum {
    ascending,
    descending,
    unknown,

    pub fn ok(self: Direction, left: usize, right: usize) bool {
        return (self == Direction.ascending and left < right) or
            (self == Direction.descending and left > right);
    }
};

pub fn isSafe(report: []const usize) SafeFor {
    if (report.len == 0 or report.len == 1) return SafeFor.part_one;

    var safe_for_1 = true;
    {
        const dir = if (report[0] < report[1]) Direction.ascending else Direction.descending;
        for (report[0 .. report.len - 1], report[1..report.len]) |left, right| {
            if (!dir.ok(left, right)) {
                safe_for_1 = false;
                break;
            }
            if (distance(usize, left, right) > 3) {
                safe_for_1 = false;
                break;
            }
        }
    }
    if (safe_for_1) return SafeFor.part_one;

    for (0..report.len) |skip_idx| {
        var dir = Direction.unknown;
        var safe_for_this_skip_idx = true;
        for (0..report.len - 1) |left_idx| {
            // Set up the indices we're checking.
            if (left_idx == skip_idx) continue;
            var right_idx = left_idx + 1;
            if (right_idx == skip_idx) {
                right_idx += 1;
            }
            if (right_idx >= report.len) {
                break;
            }

            const left = report[left_idx];
            const right = report[right_idx];
            if (left == right) {
                safe_for_this_skip_idx = false;
                break;
            }

            if (dir == Direction.unknown) {
                dir = if (left < right)
                    Direction.ascending
                else
                    Direction.descending;
            }
            if (!dir.ok(left, right)) {
                safe_for_this_skip_idx = false;
                break;
            }
        }
        if (safe_for_this_skip_idx) {
            return SafeFor.part_two;
        }
    }
    return SafeFor.never;
}

test "isSafe returns true on inputs that are too short" {
    try std.testing.expectEqual(
        SafeFor.part_one,
        isSafe(([_]usize{})[0..]),
    );
    try std.testing.expectEqual(
        SafeFor.part_one,
        isSafe(([_]usize{1})[0..]),
    );
}

test "isSafe handles repeats correctly" {
    try std.testing.expectEqual(
        SafeFor.part_two,
        isSafe(([_]usize{ 2, 2 })[0..]),
    );
    try std.testing.expectEqual(
        SafeFor.never,
        isSafe(([_]usize{ 2, 2, 2 })[0..]),
    );
    // ... including after the beginning.
    try std.testing.expectEqual(
        SafeFor.never,
        isSafe(([_]usize{ 0, 1, 2, 2, 2 })[0..]),
    );
}

test "isSafe handles same-direction sequences correctly" {
    // All increasing is safe.
    try std.testing.expectEqual(
        SafeFor.part_one,
        isSafe(([_]usize{ 1, 2, 3 })[0..]),
    );
    // All decreasing is safe.
    try std.testing.expectEqual(
        SafeFor.part_one,
        isSafe(([_]usize{ 6, 5, 4, 3 })[0..]),
    );
}

test "isSafe handles changes in direction correctly" {
    // Ascending to descending.
    try std.testing.expectEqual(
        SafeFor.part_two,
        isSafe(([_]usize{ 3, 4, 5, 4 })[0..]),
    );
    try std.testing.expectEqual(
        SafeFor.never,
        isSafe(([_]usize{ 3, 4, 5, 4, 5 })[0..]),
    );
    // Descending to ascending.
    try std.testing.expectEqual(
        SafeFor.never,
        isSafe(([_]usize{ 6, 5, 4, 3, 4, 5 })[0..]),
    );
}

pub fn distance(comptime T: type, left: T, right: T) T {
    if (left >= right) {
        return left - right;
    }
    return right - left;
}
