// File structure bitten from https://kristoff.it/blog/advent-of-code-zig/
const std = @import("std");
const input = @embedFile("input");

const example =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
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

const Constraint = struct {
    first: []const u8,
    second: []const u8,

    fn fix(self: *const Constraint, in: []u8) !bool {
        return self._inner(in);
    }
    fn ok(self: *const Constraint, in: []u8) !bool {
        return self._inner(in);
    }

    fn _inner(self: *const Constraint, in: []u8) !bool {
        var base_idx: usize = 0;
        while (base_idx + 2 < in.len) : (base_idx += 3) {
            var check_idx: usize = base_idx + 3;
            const left = in[base_idx .. base_idx + 2];
            while (check_idx + 1 < in.len) : (check_idx += 3) {
                const right = in[check_idx .. check_idx + 2];
                if (std.mem.eql(u8, left, self.second) and
                    std.mem.eql(u8, right, self.first))
                {
                    // Save off a copy of the data so we can copy out of it.
                    var tmp: [1024]u8 = undefined;
                    _ = try std.fmt.bufPrint(&tmp, "{s}", .{in});
                    _ = try std.fmt.bufPrint(
                        in,
                        "{s}{s}{s}{s}",
                        .{
                            tmp[0..base_idx],
                            tmp[check_idx .. check_idx + 2],
                            tmp[base_idx + 2 .. check_idx],
                            tmp[base_idx .. base_idx + 2],
                        },
                    );
                    return false;
                }
            }
        }
        return true;
    }
};

fn solution(in: []const u8) ![2]usize {
    var lines = std.mem.splitScalar(u8, in, '\n');

    var constraints = std.ArrayList(Constraint).init(std.heap.page_allocator);
    try consumeOrderConstraints(
        &lines,
        &constraints,
    );
    defer constraints.deinit();

    var part_1_sum: usize = 0;
    var part_2_sum: usize = 0;
    while (lines.next()) |line| {
        var buf: [128]u8 = undefined;
        const line_copy = try std.fmt.bufPrint(&buf, "{s}", .{line});

        if (try checkConstraints(constraints.items, line_copy)) {
            part_1_sum += try std.fmt.parseInt(u8, try centerTwo(line_copy), 10);
        } else {
            // lol
            // Really this "reorder until stable" logic should happen as a sort or just inside `fix` but who cares
            try fix(constraints.items, line_copy);
            try fix(constraints.items, line_copy);
            try fix(constraints.items, line_copy);
            try fix(constraints.items, line_copy);
            part_2_sum += try std.fmt.parseInt(u8, try centerTwo(line_copy), 10);
        }
    }

    return .{ part_1_sum, part_2_sum };
}

fn consumeOrderConstraints(lines: *std.mem.SplitIterator(u8, .scalar), accum: *std.ArrayList(Constraint)) !void {
    while (lines.next()) |line| {
        // When we hit the multiple-newline divider between constraints and pages, we're done.
        if (line.len == 0) return;

        // Assume each line is 5 chars -- two 2-digit numbers separated by a pipe.
        try accum.append(Constraint{
            .first = line[0..2],
            .second = line[3..5],
        });
    }
}

fn checkConstraints(constraints: []const Constraint, line: []u8) !bool {
    for (constraints) |c| {
        if (!(try c.ok(line))) return false;
    }
    return true;
}

fn fix(constraints: []const Constraint, line: []u8) !void {
    for (constraints) |c| {
        _ = try c.fix(line);
    }
}

test "example" {
    var lines = std.mem.splitScalar(u8, example, '\n');

    var orderConstraintsList = std.ArrayList(Constraint).init(std.testing.allocator);
    try consumeOrderConstraints(
        &lines,
        &orderConstraintsList,
    );
    defer orderConstraintsList.deinit();

    for (orderConstraintsList.items, [_]Constraint{
        Constraint{ .first = "47", .second = "53" },
        Constraint{ .first = "97", .second = "13" },
        Constraint{ .first = "97", .second = "61" },
        Constraint{ .first = "97", .second = "47" },
        Constraint{ .first = "75", .second = "29" },
        Constraint{ .first = "61", .second = "13" },
        Constraint{ .first = "75", .second = "53" },
        Constraint{ .first = "29", .second = "13" },
        Constraint{ .first = "97", .second = "29" },
        Constraint{ .first = "53", .second = "29" },
        Constraint{ .first = "61", .second = "53" },
        Constraint{ .first = "97", .second = "53" },
        Constraint{ .first = "61", .second = "29" },
        Constraint{ .first = "47", .second = "13" },
        Constraint{ .first = "75", .second = "47" },
        Constraint{ .first = "97", .second = "75" },
        Constraint{ .first = "47", .second = "61" },
        Constraint{ .first = "75", .second = "61" },
        Constraint{ .first = "47", .second = "29" },
        Constraint{ .first = "75", .second = "13" },
        Constraint{ .first = "53", .second = "13" },
    }) |actual, expected| {
        try std.testing.expectEqualSlices(u8, expected.first, actual.first);
        try std.testing.expectEqualSlices(u8, expected.second, actual.second);
    }

    var rest_of: [6][]const u8 = undefined;
    for (0..6) |idx| {
        const n = lines.next();
        rest_of[idx] = n.?;
    }

    // First and last are what we expect; in-betweeners should obviously be
    // correcct if these are.
    {
        var buf: [32]u8 = undefined;
        try std.testing.expectEqualSlices(u8, rest_of[0], try std.fmt.bufPrint(&buf, "75,47,61,53,29", .{}));
        try std.testing.expectEqualSlices(u8, rest_of[5], try std.fmt.bufPrint(&buf, "97,13,75,29,47", .{}));

        // Done consuming.
        try std.testing.expect(lines.peek() == null);

        //Interesting failure cases.
        const should_fail_5th = Constraint{ .first = "29", .second = "13" };
        try std.testing.expect(!try should_fail_5th.ok(try std.fmt.bufPrint(&buf, "61,13,29", .{})));
        try std.testing.expect(!try should_fail_5th.ok(try std.fmt.bufPrint(&buf, "13,29", .{})));
        // Check em all.
        const constraints = orderConstraintsList.items;
        try std.testing.expect(try checkConstraints(constraints, try std.fmt.bufPrint(&buf, "75,47,61,53,29", .{})));
        try std.testing.expect(try checkConstraints(constraints, try std.fmt.bufPrint(&buf, "97,61,53,29,13", .{})));
        try std.testing.expect(try checkConstraints(constraints, try std.fmt.bufPrint(&buf, "75,29,13", .{})));
        try std.testing.expect(!try checkConstraints(constraints, try std.fmt.bufPrint(&buf, "75,97,47,61,53", .{})));
        try std.testing.expect(!try checkConstraints(constraints, try std.fmt.bufPrint(&buf, "61,13,29", .{})));
        try std.testing.expect(!try checkConstraints(constraints, try std.fmt.bufPrint(&buf, "97,13,75,29,47", .{})));
    }

    // Part 2 fix.
    {
        var buf: [1024]u8 = undefined;
        var copy_to = try std.fmt.bufPrint(&buf, "61,13,29", .{});
        try fix(orderConstraintsList.items, copy_to[0..]);
        try std.testing.expectEqualSlices(u8, "61,29,13", copy_to);
    }
    {
        var buf: [1024]u8 = undefined;
        var copy_to = try std.fmt.bufPrint(&buf, "75,97,47,61,53", .{});
        try fix(orderConstraintsList.items, copy_to[0..]);
        try std.testing.expectEqualSlices(u8, "97,75,47,61,53", copy_to);
    }
}

test "part 1" {
    try std.testing.expectEqual(143, (try solution(example))[0]);
    try std.testing.expectEqual(4872, (try solution(input))[0]);
}
test "part 2" {
    try std.testing.expectEqual(123, (try solution(example))[1]);
}

const E = error{ NonEvenLengthError, TooShortError };

fn centerTwo(in: []const u8) ![]const u8 {
    if (in.len % 2 != 0) return E.NonEvenLengthError;
    if (in.len < 3) return E.TooShortError;

    return in[in.len / 2 - 1 .. in.len / 2 + 1];
}
