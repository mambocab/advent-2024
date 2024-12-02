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

    try stdout.print("{any}\n", .{countSafeLines(v)});
}

pub fn countSafeLines(in: []const u8) !usize {
    var safe_line_count: usize = 0;
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
        if (safe) safe_line_count += 1;
    }
    return safe_line_count;
}

test "part 1 example" {
    try std.testing.expectEqual(2, countSafeLines(example));
}

const Direction = enum {
    ascending,
    descending,

    pub fn ok(self: Direction, left: usize, right: usize) bool {
        return (self == Direction.ascending and left < right) or
            (self == Direction.descending and left > right);
    }
};

pub fn isSafe(report: []const usize) bool {
    if (report.len == 0 or report.len == 1) return true;
    if (report[0] == report[1]) return false;

    const dir = if (report[0] < report[1]) Direction.ascending else Direction.descending;
    for (report[0 .. report.len - 1], report[1..report.len]) |left, right| {
        if (!dir.ok(left, right)) return false;
        if (distance(usize, left, right) > 3) return false;
    }

    return true;
}

test "isSafe returns true on inputs that are too short" {
    try std.testing.expectEqual(
        true,
        isSafe(([_]usize{})[0..]),
    );
    try std.testing.expectEqual(
        true,
        isSafe(([_]usize{1})[0..]),
    );
}

test "isSafe handles repeats correctly" {
    // Repeats are unsafe...
    try std.testing.expectEqual(
        false,
        isSafe(([_]usize{ 2, 2 })[0..]),
    );
    // ... including after the beginning.
    try std.testing.expectEqual(
        false,
        isSafe(([_]usize{ 0, 1, 2, 2 })[0..]),
    );
}

test "isSafe handles same-direction sequences correctly" {
    // All increasing is safe.
    try std.testing.expectEqual(
        true,
        isSafe(([_]usize{ 1, 2, 3 })[0..]),
    );
    // All decreasing is safe.
    try std.testing.expectEqual(
        true,
        isSafe(([_]usize{ 6, 5, 4, 3 })[0..]),
    );
}

test "isSafe handles changes in direction correctly" {
    // Ascending to descending.
    try std.testing.expectEqual(
        false,
        isSafe(([_]usize{ 3, 4, 5, 4 })[0..]),
    );
    // Descending to ascending.
    try std.testing.expectEqual(
        false,
        isSafe(([_]usize{ 6, 5, 4, 3, 4 })[0..]),
    );
}

pub fn distance(comptime T: type, left: T, right: T) T {
    if (left >= right) {
        return left - right;
    }
    return right - left;
}
