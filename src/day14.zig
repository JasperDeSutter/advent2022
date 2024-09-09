const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("14", solve);

const BitSet = [1000 * 256]bool;

const Pos = struct {
    x: u16,
    y: u8,
};

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var max: u8 = 0;

    var bitset: *BitSet = @ptrCast(try alloc.create(BitSet));
    defer alloc.free(bitset);
    @memset(bitset, false);

    {
        var lines = std.mem.tokenizeScalar(u8, input, '\n');
        while (lines.next()) |line| {
            var parts = std.mem.tokenizeSequence(u8, line, " -> ");
            var prev = Pos{ .x = 0, .y = 0 };
            while (parts.next()) |part| {
                var x = try std.fmt.parseInt(u16, part[0..3], 10);
                var y = try std.fmt.parseInt(u8, part[4..], 10);

                const xP = x;
                const yP = y;

                if (x == prev.x) {
                    if (y < prev.y) std.mem.swap(u8, &y, &prev.y);
                    for (prev.y..(y + 1)) |i| {
                        bitset[index(x, @intCast(i))] = true;
                    }
                }
                if (y == prev.y) {
                    if (x < prev.x) std.mem.swap(u16, &x, &prev.x);
                    for (prev.x..(x + 1)) |i| {
                        bitset[index(@intCast(i), y)] = true;
                    }
                }

                if (yP > max) max = yP;
                prev = Pos{ .x = xP, .y = yP };
            }
        }
    }

    const count = simulate(max, max + 1, bitset);

    const count2 = simulate(max + 2, max + 1, bitset);

    return .{ count, count + count2 };
}

fn simulate(max: u8, floor: u8, bitset: *BitSet) usize {
    var count: usize = 0;

    outer: while (true) {
        var pos = Pos{ .x = 500, .y = 0 };
        while (pos.y < max) {
            if (pos.y < floor) {
                if (!bitset[index(pos.x, pos.y + 1)]) {
                    pos.y += 1;
                    continue;
                }
                if (!bitset[index(pos.x - 1, pos.y + 1)]) {
                    pos.x -= 1;
                    pos.y += 1;
                    continue;
                }

                if (!bitset[index(pos.x + 1, pos.y + 1)]) {
                    pos.x += 1;
                    pos.y += 1;
                    continue;
                }
            }
            if (pos.y == 0) {
                return count + 1;
            }
            bitset[index(pos.x, pos.y)] = true;
            count += 1;
            continue :outer;
        }
        return count;
    }
}

fn index(x: u16, y: u8) usize {
    return @as(usize, @intCast(x)) * 256 + @as(usize, @intCast(y));
}

test {
    const input =
        \\498,4 -> 498,6 -> 496,6
        \\503,4 -> 502,4 -> 502,9 -> 494,9
    ;
    const results = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(24, results[0]);
    try std.testing.expectEqual(93, results[1]);
}
