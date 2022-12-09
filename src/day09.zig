const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    std.debug.print("positions visited (2): {any}\n", .{try simulateRope(alloc, input, 2)});
    std.debug.print("positions visited (10): {any}\n", .{try simulateRope(alloc, input, 10)});
}

const boardSize: usize = 500;

fn simulateRope(alloc: std.mem.Allocator, input: []const u8, knots: u8) !usize {
    var lines = std.mem.split(u8, input, "\n");

    var visited = try std.DynamicBitSetUnmanaged.initEmpty(alloc, boardSize * boardSize);
    defer visited.deinit(alloc);

    var positions = try alloc.alloc([2]i16, knots);
    defer alloc.free(positions);
    std.mem.set([2]i16, positions, .{ 0, 0 });

    const mid = boardSize / 2;
    visited.set(mid * mid);

    while (lines.next()) |line| {
        const dir = line[0];
        var dist = try std.fmt.parseInt(u16, line[2..], 10);

        while (dist > 0) : (dist -= 1) {
            var head = &positions[0];
            switch (dir) {
                'R' => head[0] += 1,
                'L' => head[0] -= 1,
                'U' => head[1] -= 1,
                else => head[1] += 1,
            }

            var i: usize = 1;
            var h = head.*;
            while (i < positions.len) : (i += 1) {
                var tail = &positions[i];
                var x = h[0] - tail[0];
                var y = h[1] - tail[1];

                if (x < 2 and x > -2 and y < 2 and y > -2) break;
                x = std.math.sign(x);
                y = std.math.sign(y);

                tail[0] += x;
                tail[1] += y;
                h = tail.*;

                if (i == positions.len - 1) {
                    const midI = @intCast(i16, mid);
                    const pos = @intCast(usize, h[1] + midI) * boardSize + @intCast(usize, h[0] + midI);
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
