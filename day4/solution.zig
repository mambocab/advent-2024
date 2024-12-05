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
        \\example_hardest = {any}
        \\input           = {any}
        \\
    , .{
        try solution(example_easy),
        try solution(example_hardest),
        try solution(input),
    });
}

const Errors = error{UnevenLinesError};

inline fn str_eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn solution(in: []const u8) ![2]usize {
    var part_1_count: usize = 0;
    var part_2_count: usize = 0;
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

        // For each n-wide window, check for all configuraitons.
        for (0..line_1.len) |i| {
            const check_horiz = line_1.len - i >= 4;
            const check_vert = line_4.len > 0;

            // Part 1.
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

            // Part 2.
            if (line_1.len - i >= 3 and line_3.len != 0) {
                const valid_center = line_2[i + 1] == 'A';
                const valid_down = (line_1[i] == 'M' and line_3[i + 2] == 'S' or
                    line_1[i] == 'S' and line_3[i + 2] == 'M');
                const valid_up = (line_3[i] == 'M' and line_1[i + 2] == 'S' or
                    line_3[i] == 'S' and line_1[i + 2] == 'M');
                if (valid_center and valid_down and valid_up) part_2_count += 1;
            }
        }
    }

    return .{ part_1_count, part_2_count };
}
