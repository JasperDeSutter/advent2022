const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("09", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    return .{
        try simulateRope(alloc, input, 2),
        try simulateRope(alloc, input, 10),
    };
}

const boardSize: usize = 500;
const Pos = @Vector(2, i16);

fn simulateRope(alloc: std.mem.Allocator, input: []const u8, knots: u8) !usize {
    var lines = std.mem.split(u8, input, "\n");

    var visited = try std.DynamicBitSetUnmanaged.initEmpty(alloc, boardSize * boardSize);
    defer visited.deinit(alloc);

    var positions = try alloc.alloc(Pos, knots);
    defer alloc.free(positions);
    @memset(positions, .{ 0, 0 });

    const mid = boardSize / 2;
    visited.set(mid * mid);

    while (lines.next()) |line| {
        const dir = line[0];
        var dist = try std.fmt.parseInt(u16, line[2..], 10);

        while (dist > 0) : (dist -= 1) {
            const head = &positions[0];
            head.* += switch (dir) {
                'R' => .{ 1, 0 },
                'L' => .{ -1, 0 },
                'U' => .{ 0, -1 },
                else => .{ 0, 1 },
            };

            var i: usize = 1;
            var h = head.*;
            while (i < positions.len) : (i += 1) {
                const tail = &positions[i];
                const off = h - tail.*;

                if (@reduce(.And, off > Pos{ -2, -2 }) and @reduce(.And, off < Pos{ 2, 2 })) break;

                tail.* += std.math.sign(off);
                h = tail.*;

                if (i == positions.len - 1) {
                    const midI: i16 = @intCast(mid);
                    const pos = @as(usize, @intCast(h[1] + midI)) * boardSize + @as(usize, @intCast(h[0] + midI));
                    visited.set(pos);
                }
            }
        }
    }

    return visited.count();
}

test {
    const input =
        \\R 4
        \\U 4
        \\L 3
        \\D 1
        \\R 4
        \\D 1
        \\L 5
        \\R 2
    ;

    try std.testing.expectEqual(try simulateRope(std.testing.allocator, input, 2), 13);
    try std.testing.expectEqual(try simulateRope(std.testing.allocator, input, 10), 1);

    const large_input =
        \\R 5
        \\U 8
        \\L 8
        \\D 3
        \\R 17
        \\D 10
        \\L 25
        \\U 20
    ;
    try std.testing.expectEqual(try simulateRope(std.testing.allocator, large_input, 10), 36);
}
