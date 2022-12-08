const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    std.debug.print("visibleTreeCount: {any}\n", .{try visibleTreeCount(alloc, input)});
}

fn visibleTreeCount(alloc: std.mem.Allocator, input: []const u8) !usize {
    var rows = std.ArrayList([]const u8).init(alloc);
    defer rows.deinit();
    {
        var lines = std.mem.split(u8, input, "\n");
        while (lines.next()) |line| try rows.append(line);
    }

    const width = rows.items[0].len;
    const height = rows.items.len;
    const count = height * width;
    var markers = try alloc.alloc(bool, count);
    defer alloc.free(markers);

    for (rows.items) |row, y| {
        var highest: u8 = 0;
        for (row) |tree, x| {
            if (tree > highest) {
                markers[y * width + x] = true;
                highest = tree;
            }
        }
        highest = 0;
        var i = row.len - 1;
        while (i > 0) : (i -= 1) {
            const tree = row[i];
            if (tree > highest) {
                markers[y * width + i] = true;
                highest = tree;
            }
        }
    }

    {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            var highest: u8 = 0;
            var y: usize = 0;
            while (y < height) : (y += 1) {
                const tree = rows.items[y][x];
                if (tree > highest) {
                    markers[y * width + x] = true;
                    highest = tree;
                }
            }
            y = height - 1;
            highest = 0;

            while (y > 0) : (y -= 1) {
                const tree = rows.items[y][x];
                if (tree > highest) {
                    markers[y * width + x] = true;
                    highest = tree;
                }
            }
        }
    }

    var total: u32 = 0;
    for (markers) |marker| {
        if (marker) total += 1;
    }
    return total;
}

test {
    const input =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;

    try std.testing.expectEqual(try visibleTreeCount(std.testing.allocator, input), 21);
}
