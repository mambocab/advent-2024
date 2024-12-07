// File structure bitten from https://kristoff.it/blog/advent-of-code-zig/
const std = @import("std");
const input = @embedFile("input");

const example =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;

pub fn main() !void {
    var stdout_bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer {
        // For this simple case we don't care about handling this class of error.
        // Ignore it so we can use defer.
        _ = stdout_bw.flush() catch {};
    }
    var stdout = stdout_bw.writer();

    try stdout.print("example = {any}\n", .{try solution(example)});
    try stdout.print("input = {any}\n", .{try solution(input)});
}

fn solution(in: []const u8) ![2]usize {
    _ = in;
    var part_1_sum: usize = 0;
    var part_2_sum: usize = 0;
    part_1_sum += 0;
    part_2_sum += 0;
    return .{ part_1_sum, part_2_sum };
}
