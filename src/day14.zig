const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("13", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;

    var min: [2]u8 = .{ 255, 255 };
    var max: [2]u8 = .{ 0, 0 };

    var bitset = std.bit_set.ArrayBitSet(usize, 256 * 256).initEmpty();
    {
        var lines = std.mem.tokenizeScalar(u8, input, '\n');
        while (lines.next()) |line| {
            var parts = std.mem.tokenizeSequence(u8, line, " -> ");
            var prev: [2]u8 = .{ 0, 0 };
            while (parts.next()) |part| {
                var x: u8 = @intCast(try std.fmt.parseInt(u16, part[0..3], 10) - 400);
                var y = try std.fmt.parseInt(u8, part[4..], 10);

                const xP = x;
                const yP = y;

                if (x == prev[0]) {
                    if (y < prev[1]) std.mem.swap(u8, &y, &prev[1]);
                    for (prev[1]..(y + 1)) |i| {
                        bitset.set(index(x, @intCast(i)));
                    }
                }
                if (y == prev[1]) {
                    if (x < prev[0]) std.mem.swap(u8, &x, &prev[0]);
                    for (prev[0]..(x + 1)) |i| {
                        bitset.set(index(@intCast(i), y));
                    }
                }

                min = .{ @min(min[0], x), @min(min[1], y) };
                max = .{ @max(max[0], x), @max(max[1], y) };

                prev = .{ xP, yP };
            }
        }
    }

    var count: usize = 0;

    outer: while (true) {
        var pos: [2]u8 = .{ 100, 0 };
        while (pos[1] <= max[1]) {
            if (!bitset.isSet(index(pos[0], pos[1] + 1))) {
                pos[1] += 1;
                continue;
            }
            if (!bitset.isSet(index(pos[0] - 1, pos[1] + 1))) {
                pos[0] -= 1;
                pos[1] += 1;
                continue;
            }
            if (!bitset.isSet(index(pos[0] + 1, pos[1] + 1))) {
                pos[0] += 1;
                pos[1] += 1;
                continue;
            }
            bitset.set(index(pos[0], pos[1]));
            count += 1;
            continue :outer;
        }
        break;
    }

    return .{ count, 0 };
}

fn index(x: u8, y: u8) usize {
    return @as(usize, @intCast(x)) + @as(usize, @intCast(y)) * 256;
}

test {
    const input =
        \\498,4 -> 498,6 -> 496,6
        \\503,4 -> 502,4 -> 502,9 -> 494,9
    ;
    const results = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(24, results[0]);
    // try std.testing.expectEqual(93, results[1]);
}
