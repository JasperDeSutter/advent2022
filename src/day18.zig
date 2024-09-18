const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("18", solve);

const OpenMap = std.ArrayListUnmanaged(bool);

const width: usize = 8;

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var list = std.ArrayListUnmanaged([3]u8){};
    defer list.deinit(alloc);

    var max: [3]u8 = .{ 0, 0, 0 };
    while (lines.next()) |line| {
        var numbers = std.mem.tokenizeScalar(u8, line, ',');
        var ns: [3]u8 = undefined;
        for (&ns) |*n| {
            n.* = try std.fmt.parseInt(u8, numbers.next().?, 10);
        }
        if (ns[0] > max[0]) max[0] = ns[0];
        if (ns[1] > max[1]) max[1] = ns[1];
        if (ns[2] > max[2]) max[2] = ns[2];
        try list.append(alloc, ns);
    }

    std.mem.sortUnstable([3]u8, list.items, {}, struct {
        pub fn cmp(_: void, a: [3]u8, b: [3]u8) bool {
            if (a[0] != b[0]) return a[0] < b[0];
            if (a[1] != b[1]) return a[1] < b[1];
            return a[2] < b[2];
        }
    }.cmp);

    const stride = @as(usize, max[2] + 1);

    var map = try alloc.alloc(u8, stride * (max[1] + 1)); // slices of y * z
    defer alloc.free(map);
    @memset(map, 0);

    var i = for (list.items, 0..) |item, i| {
        if (item[0] > 0) break i;
        const idx = item[2] + item[1] * stride;
        map[idx] = 1;
    } else 0;

    var count: usize = list.items.len * 6;

    for (1..(max[0] + 1)) |x| {
        var prev: usize = 0;
        while (i < list.items.len) : (i += 1) {
            const item = list.items[i];
            if (item[0] > x) {
                @memset(map[prev..], 0);
                break;
            }

            const idx = item[2] + item[1] * stride;
            if (map[idx] == 1) { // on top of a cube
                count -= 2;
            }

            @memset(map[prev..idx], 0);
            map[idx] = 1;

            if (idx >= 1 and map[idx - 1] == 1) {
                count -= 2;
            }
            if (idx >= stride and map[idx - stride] == 1) {
                count -= 2;
            }

            prev = idx + 1;
        }
        @memset(map[prev..], 0);
    }

    return .{ count, count };
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
    try std.testing.expectEqual(58, results[1]);
}
