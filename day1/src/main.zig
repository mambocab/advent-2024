const std = @import("std");

pub fn main() !void {
    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer {
        // Don't do this in prod but here we can just ignore errors and get to
        // use defer.
        _ = bw.flush() catch null;
    }
    var stdout = bw.writer();

    const file_name = "input";
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    const alloc = std.heap.page_allocator;
    var left = std.ArrayList(usize).init(alloc);
    defer left.deinit();
    var right = std.ArrayList(usize).init(alloc);
    defer right.deinit();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const result = try splitAndConvert(line);
        try left.append(result[0]);
        try right.append(result[1]);
    }
    std.sort.heap(usize, left.items, {}, std.sort.asc(usize));
    std.sort.heap(usize, right.items, {}, std.sort.asc(usize));

    var sum: usize = 0;
    for (left.items, right.items) |lv, rv| {
        sum += distance(usize, lv, rv);
    }
    try stdout.print("{d}\n", .{sum});
}

pub fn splitAndConvert(line: []const u8) ![2]usize {
    // Head of first, tail of first, head of second, tail of second.
    var boundaries = [4]usize{ undefined, undefined, undefined, undefined };
    var boundaries_idx: usize = 0;
    var line_idx: usize = 0;

    while (true) : (line_idx += 1) {
        if (line_idx >= line.len) {
            boundaries[boundaries_idx] = line_idx;
            break;
        }
        // We always skip spaces.
        if (line[line_idx] == ' ') {
            // If this space marked the end of a number, note that boundary.
            if (boundaries_idx == 1 or boundaries_idx == 3) {
                boundaries[boundaries_idx] = line_idx;
                boundaries_idx += 1;
            }
            continue;
        } else {
            // If this non-space marked the beginning of a number, note that boundary.
            if (boundaries_idx == 0 or boundaries_idx == 2) {
                boundaries[boundaries_idx] = line_idx;
                boundaries_idx += 1;
            }
        }
    }
    const first_number: []const u8 = line[boundaries[0]..boundaries[1]];
    const second_number: []const u8 = line[boundaries[2]..boundaries[3]];
    const first_parsed = try std.fmt.parseInt(usize, first_number, 10);
    const second_parsed = try std.fmt.parseInt(usize, second_number, 10);
    return [_]usize{ first_parsed, second_parsed };
}

pub fn distance(comptime T: type, left: T, right: T) T {
    if (left > right) {
        return left - right;
    }
    return right - left;
}

const testalloc = std.testing.allocator;
const expectEqualDeep = std.testing.expectEqualDeep;

test "splitConvertAndSort should do that" {
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    var in_stream = std.io.fixedBufferStream(input);
    var in_reader = in_stream.reader();

    var buf: [1024]u8 = undefined; // Assume each line is 1024 chars or less.

    var left = std.ArrayList(usize).init(testalloc);
    defer left.deinit();
    var right = std.ArrayList(usize).init(testalloc);
    defer right.deinit();

    while (try in_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const result = try splitAndConvert(line);
        try left.append(result[0]);
        try right.append(result[1]);
    }

    try expectEqualDeep(([_]usize{ 3, 4, 2, 1, 3, 3 })[0..], left.items);
    try expectEqualDeep(([_]usize{ 4, 3, 5, 3, 9, 3 })[0..], right.items);
}

test "test conversion for long lines" {
    try expectEqualDeep([2]usize{ 12345, 23456 }, try splitAndConvert("12345       23456"));
}
