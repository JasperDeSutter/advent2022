const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("18", solve);

const OpenMap = std.ArrayListUnmanaged(bool);

const width: usize = 8;

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var list = std.ArrayListUnmanaged([3]u8){};
    defer list.deinit(alloc);

    while (lines.next()) |line| {
        var numbers = std.mem.tokenizeScalar(u8, line, ',');
        var ns: [3]u8 = undefined;
        for (&ns) |*n| {
            n.* = try std.fmt.parseInt(u8, numbers.next().?, 10);
        }
        try list.append(alloc, ns);
    }

    var count: usize = list.items.len * 6;

    for (list.items, 0..) |item, i| {
        const x = item[0];
        const y = item[1];
        const z = item[2];
        const sum = x + y + z;

        for (list.items[0..i]) |item2| {
            const equals = @as(usize, @intFromBool(x == item2[0])) + @as(usize, @intFromBool(y == item2[1])) + @as(usize, @intFromBool(z == item2[2]));
            const sum2 = item2[0] + item2[1] + item2[2];
            if (equals == 2 and (sum + 1 == sum2 or sum == sum2 + 1)) {
                count -= 2;
            }
        }
    }

    return .{ count, 0 };
}

test {
    const input =
        \\2,2,2
        \\1,2,2
        \\3,2,2
        \\2,1,2
        \\2,3,2
        \\2,2,1
        \\2,2,3
        \\2,2,4
        \\2,2,6
        \\1,2,5
        \\3,2,5
        \\2,1,5
        \\2,3,5
    ;
    const results = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(64, results[0]);
    // try std.testing.expectEqual(1_514_285_714_288, results[1]);
}
