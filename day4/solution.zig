// File structure bitten from https://kristoff.it/blog/advent-of-code-zig/
const std = @import("std");
const input = @embedFile("input");

const example_easy =
    \\..X...
    \\.SAMX.
    \\.A..A.
    \\XMAS.S
    \\.X....
;
const example_harder =
    \\....XXMAS.
    \\.SAMXMS...
    \\...S..A...
    \\..A.A.MS.X
    \\XMASAMX.MM
    \\X.....XA.A
    \\S.S.S.S.SS
    \\.A.A.A.A.A
    \\..M.M.M.MM
    \\.X.X.XMASX
;
const example_hardest =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;

pub fn main() !void {
    var stdout_bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer {
        // For this simple case we don't care about handling this class of error.
        // Ignore it so we can use defer.
        _ = stdout_bw.flush() catch {};
    }
    var stdout = stdout_bw.writer();

    try stdout.print(
        \\example_easy    = {any}
        \\example_harder  = {any}
        \\example_hardest = {any}
        \\input           = {any}
        \\
    , .{
        try solution(example_easy),
        try solution(example_harder),
        try solution(example_hardest),
        try solution(input),
    });
}

const Errors = error{UnevenLinesError};

inline fn str_eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn solution(in: []const u8) !usize {
    // There are TKTKTK valid configurations of XMAS in the word search:
    //
    // 1 and 2: Horizontal configurations:
    // ```
    // XMAS
    // SAMX
    // ```
    // 3 and 4: vertical configurations:
    //
    // ```
    // XS
    // MA
    // AM
    // SX
    // ```
    //
    // 5 and 6: down and to the right:
    //
    // ```
    // X....S...
    // .M....A..
    // ..A....M.
    // ...S....X
    // ```
    //
    // and 7 and 8: up and to the right:
    // ```
    // ...S...X
    // ..A...M.
    // .M...A..
    // X...S...
    // ```
    //
    // ... So part 1 is easy. Just check for all of those.

    var part_1_count: usize = 0;
    var lines = std.mem.splitScalar(u8, in, '\n');

    // Pre-populate. Leave line 1 undefined so all iterations can be the same.
    var line_1: []const u8 = "";
    var line_2: []const u8 = lines.next() orelse "";
    var line_3: []const u8 = lines.next() orelse "";
    var line_4: []const u8 = lines.next() orelse "";

    while (true) {
        const new_line = lines.next() orelse "";

        // "Rotate" 1 back, with line 1 falling off the "back" of the window.
        line_1 = line_2;
        line_2 = line_3;
        line_3 = line_4;
        line_4 = new_line;

        if (line_1.len == 0) break;

        // For each 4-wide window, check for all 8 configuraitons.
        for (0..line_1.len) |i| {
            const check_horiz = line_1.len - i >= 4;
            const check_vert = line_4.len > 0;

            // Check for horizontal configurations if we have enough characters.
            if (check_horiz) {
                const horiz_candidate = line_1[i .. i + 4];
                if (str_eql(horiz_candidate, "XMAS") or str_eql(horiz_candidate, "SAMX")) {
                    part_1_count += 1;
                }
            }

            // Check for vertical configurations if we have enough lines.
            if (check_vert) {
                const c0 = line_1[i];
                const c1 = line_2[i];
                const c2 = line_3[i];
                const c3 = line_4[i];
                if (
                // Vertical "XMAS".
                (c0 == 'X' and c1 == 'M' and c2 == 'A' and c3 == 'S') or
                    // Vertical "SAMX".
                    (c0 == 'S' and c1 == 'A' and c2 == 'M' and c3 == 'X'))
                {
                    part_1_count += 1;
                }
            }

            if (check_horiz and check_vert) {
                {
                    // Check for down-and-to-the-right configurations.
                    const c0 = line_1[i];
                    const c1 = line_2[i + 1];
                    const c2 = line_3[i + 2];
                    const c3 = line_4[i + 3];
                    if (
                    // "XMAS".
                    (c0 == 'X' and c1 == 'M' and c2 == 'A' and c3 == 'S') or
                        // "SAMX".
                        (c0 == 'S' and c1 == 'A' and c2 == 'M' and c3 == 'X'))
                    {
                        part_1_count += 1;
                    }
                }
                {
                    // Check for up-and-to-the-right configurations.
                    const c0 = line_4[i];
                    const c1 = line_3[i + 1];
                    const c2 = line_2[i + 2];
                    const c3 = line_1[i + 3];
                    if (
                    // "XMAS".
                    (c0 == 'X' and c1 == 'M' and c2 == 'A' and c3 == 'S') or
                        // "SAMX".
                        (c0 == 'S' and c1 == 'A' and c2 == 'M' and c3 == 'X'))
                    {
                        part_1_count += 1;
                    }
                }
            }
        }
    }

    return part_1_count;
}

test "simple" {
    const one_count_inputs: [5][]const u8 = .{
        \\XMAS
        ,
        \\.S
        \\.A
        \\.M
        \\.X
        ,
        \\X...
        \\.M..
        \\..A.
        \\...S
        ,
        \\S...
        \\.A..
        \\..M.
        \\...X
        ,
        \\...X
        \\..M.
        \\.A..
        \\S...
    };
    for (one_count_inputs) |s| {
        if (std.testing.expectEqual(1, try solution(s))) {} else |e| {
            return e;
        }
    }
}

test "test with two" {
    try std.testing.expectEqual(2, try solution(
        \\SAMX
        \\.A..
        \\..M.
        \\...X
    ));
}
