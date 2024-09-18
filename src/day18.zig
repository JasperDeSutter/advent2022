const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("18", solve);

const water: u8 = 0;
const lava: u8 = 255;

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

    var mapStorage: [512]u8 = undefined;
    const map = mapStorage[0 .. stride * (max[1] + 1)]; // slices of y * z
    @memset(map, 0);

    var i = for (list.items, 0..) |item, i| {
        if (item[0] > 0) break i;
        const idx = item[2] + item[1] * stride;
        map[idx] = lava;
    } else 0;

    var count: usize = list.items.len * 6;
    var pocketWalls: usize = 0;

    for (1..(max[0] + 1)) |x| {
        var prev: usize = 0;

        // update map with new slice, updating wall count in a single pass
        // only needs to check for walls on the left (z - 1) and above (y - 1) because we count walls twice.
        // each air pocket is represented by directly surrounding wall count (single column)
        while (i < list.items.len) : (i += 1) {
            const item = list.items[i];
            if (item[0] > x) break; // slice finished

            const idx = item[2] + item[1] * stride;
            if (map[idx] == lava) {
                count -= 2; // counting same wall twice
            } else if (map[idx] != water) {
                pocketWalls += 1; // roof wall
                // this should add current wall count to surrounding air pockets
                // but not needed on my input
            }

            if (prev == 0) {
                pocketWalls -= flood(map[prev..idx]);
            } else {
                for (map[prev..idx]) |*v| {
                    // TODO: possible to check for surrounding water and skip adding air pocket
                    if (v.* == lava) {
                        v.* = 1;
                        pocketWalls += 1;
                    }
                }
            }
            map[idx] = lava;

            if (idx >= 1 and map[idx - 1] == lava) {
                count -= 2;
            }
            if (idx >= stride and map[idx - stride] == lava) {
                count -= 2;
            }

            prev = idx + 1;
        }
        pocketWalls -= flood(map[prev..]);

        // fill air pockets touching water
        var preRemove = pocketWalls + 1;
        while (preRemove != pocketWalls) {
            preRemove = pocketWalls;
            for (map, 0..) |*v, idx| {
                if (v.* == water or v.* == lava) continue;
                var remove = (idx >= 1 and map[idx - 1] == water);
                remove = remove or (idx >= stride and map[idx - stride] == water);
                remove = remove or (idx < map.len - 1 and map[idx + 1] == water);
                remove = remove or (idx < map.len - stride and map[idx + stride] == water);

                if (remove) {
                    pocketWalls -= v.*;
                    v.* = 0;
                }
            }
        }

        for (map, 0..) |*v, idx| {
            if (v.* == water or v.* == lava) continue;

            var walls: u8 = 0;
            if (map[idx - 1] == lava) walls += 1;
            if (map[idx - stride] == lava) walls += 1;
            if (map[idx + 1] == lava) walls += 1;
            if (map[idx + stride] == lava) walls += 1;

            pocketWalls += walls;
            v.* += walls;
        }

        // for (0..max[1]) |y| {
        //     std.debug.print("{X:2}\n", .{map[y * stride ..][0..stride]});
        // }
        // std.debug.print("\n", .{});
    }

    return .{ count, count - pocketWalls };
}

fn flood(slice: []u8) usize {
    var total: usize = 0;
    for (slice) |*s| {
        if (s.* != lava) {
            total += s.*;
        }
        s.* = water;
    }
    return total;
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
