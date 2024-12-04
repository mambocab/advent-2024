// File structure bitten from https://kristoff.it/blog/advent-of-code-zig/
const std = @import("std");
const input = @embedFile("input");
const example =
    \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
;

pub fn main() !void {
    var stdout_bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer {
        // For this simple case we don't care about handling this class of error.
        // Ignore it so we can use defer.
        _ = stdout_bw.flush() catch {};
    }
    var stdout = stdout_bw.writer();

    try stdout.print("part 1 = {any}\n", .{try part1(input)});
}

fn part1(in: []const u8) !usize {
    var muls = std.mem.splitSequence(u8, in, "mul(");
    var sum: usize = 0;
    while (muls.next()) |mul| {
        const untilParen = std.mem.sliceTo(mul, ')');
        if (untilParen.len > 0) {
            if (parse2Args(untilParen)) |args| {
                sum += args[0] * args[1];
            } else |_| {}
        }
    }
    return sum;
}

test "example" {
    try std.testing.expectEqual(161, try part1(example));
}

const Error = error{TooManyNumbersError};

/// parseMul takes a string of the form \d+,\d+ and returns the two numbers.
fn parse2Args(in: []const u8) ![2]usize {
    var result: [2]usize = undefined;
    var nums = std.mem.tokenizeScalar(u8, in, ',');
    var i: u2 = 0;
    while (nums.next()) |num| : (i += 1) {
        const parsed = try std.fmt.parseInt(usize, num, 10);
        if (i > 1) return Error.TooManyNumbersError;
        result[i] = parsed;
    }
    return result;
}

test "parseMul" {
    // Simplest happy path.
    try std.testing.expectEqual(.{ 1, 2 }, try parse2Args("1,2"));
    // Slightly harder.
    try std.testing.expectEqual(.{ 11, 2222 }, try parse2Args("11,2222"));
    // Spaces or other extra stuff is an error.
    try std.testing.expectError(error.InvalidCharacter, parse2Args("1 ,2"));
    // Too many commas is an error.
    try std.testing.expectError(Error.TooManyNumbersError, parse2Args("1,2,3"));
}
