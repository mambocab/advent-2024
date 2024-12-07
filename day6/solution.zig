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

const Error = error{
    UnevenLinesError,
    InvalidCellSpecifier,
    SteppingOutOfBoundsError,
    NonGuardCellError,
    DestinationCellIntegrityError,
    SourceCellIntegrityError,
    CouldntFindGuardError,
};

const Cell = enum {
    border, // Not present in input.
    untracked, // Guard hasn't stepped on.
    tracked, // Guard has stepped on.
    obstacle,
    guard_north,
    guard_east,
    guard_south,
    guard_west,

    fn char(self: *const Cell) ?u8 {
        return switch (self.*) {
            .border => null,
            .untracked => '.',
            .tracked => 'X',
            .obstacle => '#',
            .guard_north => '^',
            .guard_east => '>',
            .guard_south => 'v',
            .guard_west => '<',
        };
    }

    fn from(c: u8) !Cell {
        return switch (c) {
            '.' => .untracked,
            'X' => .tracked,
            '#' => .obstacle,
            '^' => .guard_north,
            '>' => .guard_east,
            'v' => .guard_south,
            '<' => .guard_west,
            else => Error.InvalidCellSpecifier,
        };
    }

    fn turnRight(self: *const Cell) !Cell {
        return switch (self.*) {
            .guard_north => .guard_east,
            .guard_east => .guard_south,
            .guard_south => .guard_west,
            .guard_west => .guard_north,
            else => Error.NonGuardCellError,
        };
    }
};

const Direction = enum {
    north,
    east,
    south,
    west,

    fn rowMod(self: *const Direction, in: usize) usize {
        return switch (self.*) {
            .north => in - 1,
            .south => in + 1,
            .east, .west => in,
        };
    }

    fn colMod(self: *const Direction, in: usize) usize {
        return switch (self.*) {
            .east => in + 1,
            .west => in - 1,
            .north, .south => in,
        };
    }
};
const Point = struct { row_idx: usize, col_idx: usize };

const Lab = struct {
    floor: [][]Cell,
    tracked_count: usize,
    allocator: std.mem.Allocator,

    fn init(self: *Lab, alloc: std.mem.Allocator, in: []const u8) !void {
        self.allocator = alloc;
        self.tracked_count = 0;

        var lines = std.mem.splitScalar(u8, in, '\n');
        var expected_line_length: ?usize = null;

        var rows = std.ArrayList([]Cell).init(alloc);

        while (lines.next()) |line| {
            if (expected_line_length) |expected| {
                // If we expected a particular line length, make sure the current line is valid.
                if (line.len == 0) {
                    continue;
                } else if (line.len != expected) {
                    // On subsequent passes, make sure our input is valid.
                    return Error.UnevenLinesError;
                }
            } else {
                // First time through, initialize the "border" row of cells.
                expected_line_length = line.len;
                var row_0 = try alloc.alloc(Cell, line.len + 2);
                for (0..row_0.len) |idx| row_0[idx] = Cell.border;
                try rows.append(row_0);
            }

            // Allocate memory for storing the row, including a column on each end for the border.
            var row = try alloc.alloc(Cell, line.len + 2);
            row[0] = Cell.border;
            for (line, 1..) |char, idx| {
                row[idx] = try Cell.from(char);
            }
            row[row.len - 1] = Cell.border;
            try rows.append(row);
        }

        var last_line = try alloc.alloc(Cell, expected_line_length.? + 2);
        for (0..last_line.len) |idx| last_line[idx] = Cell.border;
        try rows.append(last_line);

        self.floor = try rows.toOwnedSlice();
    }

    fn string(self: *Lab, buf: []u8) ![]u8 {
        var buf_idx: usize = 0;
        for (self.floor, 0..) |row, row_idx| {
            _ = row_idx;
            for (row, 0..) |cell, col_idx| {
                _ = col_idx;
                buf[buf_idx] = cell.char() orelse '+';
                buf_idx += 1;
            }
            buf[buf_idx] = '\n';
            buf_idx += 1;
        }
        return buf;
    }

    fn tracked(self: *Lab) usize {
        var result: usize = 0;
        for (self.floor) |row| {
            for (row) |cell| {
                if (cell == .tracked) result += 1;
            }
        }
        return result;
    }

    fn deinit(self: *Lab) void {
        for (self.floor) |row| self.allocator.free(row);
        self.allocator.free(self.floor);
    }

    /// step returns true as long as there's more work to do for compatibility with while.
    fn step(self: *Lab) !bool {
        for (self.floor, 0..) |row, row_idx| {
            for (row, 0..) |cell, col_idx| {
                const p = Point{ .row_idx = row_idx, .col_idx = col_idx };

                return switch (cell) {
                    Cell.guard_north => try self.update_guard(p, Direction.north),
                    Cell.guard_east => try self.update_guard(p, Direction.east),
                    Cell.guard_south => try self.update_guard(p, Direction.south),
                    Cell.guard_west => try self.update_guard(p, Direction.west),
                    else => continue,
                };
            }
        }
        return Error.CouldntFindGuardError;
    }

    /// step returns true if we made an update.
    fn update_guard(self: *Lab, point: Point, direction: Direction) !bool {
        if (point.row_idx == 0 or point.row_idx == self.floor.len - 1 or point.col_idx == 0 or point.col_idx == self.floor[point.col_idx].len - 1) {
            return false;
        }
        const orig = self.floor[point.row_idx][point.col_idx];
        const dest_row = direction.rowMod(point.row_idx);
        const dest_col = direction.colMod(point.col_idx);
        const dest = self.floor[dest_row][dest_col];
        try switch (dest) {
            .border, .tracked, .untracked => {
                self.floor[dest_row][dest_col] = orig;
                self.floor[point.row_idx][point.col_idx] = .tracked;
            },
            .guard_north, .guard_west, .guard_south, .guard_east => Error.DestinationCellIntegrityError,
            .obstacle => self.floor[point.row_idx][point.col_idx] = try orig.turnRight(),
        };
        return true;
    }
};

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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lab: Lab = undefined;
    try lab.init(alloc, in);

    // Walk the whole course.
    while (try lab.step()) {}
    return .{ lab.tracked(), 0 };
}

test "part 1" {
    var lab: Lab = undefined;
    try lab.init(std.testing.allocator, example);
    defer lab.deinit();
    var buf: [2048]u8 = undefined;
    {
        const expect =
            \\++++++++++++
            \\+....#.....+
            \\+.........#+
            \\+..........+
            \\+..#.......+
            \\+.......#..+
            \\+..........+
            \\+.#..^.....+
            \\+........#.+
            \\+#.........+
            \\+......#...+
            \\++++++++++++
        ;
        var map = try lab.string(&buf);
        try std.testing.expectEqualSlices(u8, expect[0..], map[0..expect.len]);
    }

    while (try lab.step()) {}

    {
        const expect =
            \\++++++++++++
            \\+....#.....+
            \\+....XXXXX#+
            \\+....X...X.+
            \\+..#.X...X.+
            \\+..XXXXX#X.+
            \\+..X.X.X.X.+
            \\+.#XXXXXXX.+
            \\+.XXXXXXX#.+
            \\+#XXXXXXX..+
            \\+......#X..+
            \\++++++++v+++
        ;
        var map = try lab.string(&buf);
        try std.testing.expectEqualSlices(u8, expect[0..], map[0..expect.len]);
    }
}
