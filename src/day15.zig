const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("15", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    return try solveParameterized(alloc, input, 2_000_000, 4_000_000);
}

fn solveParameterized(alloc: std.mem.Allocator, input: []const u8, p1Row: i32, p2Size: i32) anyerror![2]usize {
    var beaconsOnRow = std.AutoHashMapUnmanaged(i32, void){};
    defer beaconsOnRow.deinit(alloc);

    var sensors = std.ArrayListUnmanaged([3]i32){};
    defer sensors.deinit(alloc);

    var ranges = std.ArrayListUnmanaged([2]i32){};
    defer ranges.deinit(alloc);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var part = line["Sensor at x=".len..];
        var i: usize = 0;
        while (part[i] != ',') i += 1;
        const sensorX = try std.fmt.parseInt(i32, part[0..i], 10);

        part = part[i + ", y=".len ..];
        i = 0;
        while (part[i] != ':') i += 1;
        const sensorY = try std.fmt.parseInt(i32, part[0..i], 10);

        part = part[i + ": closest beacon is at x=".len ..];
        i = 0;
        while (part[i] != ',') i += 1;
        const beaconX = try std.fmt.parseInt(i32, part[0..i], 10);

        part = part[i + ", y=".len ..];
        const beaconY = try std.fmt.parseInt(i32, part, 10);

        const distance = @abs(sensorX - beaconX) + @abs(sensorY - beaconY);
        try sensors.append(alloc, .{ sensorX, sensorY, @intCast(distance) });

        const rowDist = @abs(sensorY - p1Row);
        if (distance > rowDist) {
            if (beaconY == p1Row) try beaconsOnRow.put(alloc, beaconX, {});
            const distToRow: i32 = @intCast(distance - rowDist);
            const start = sensorX - distToRow;
            const end = sensorX + distToRow + 1;
            try ranges.append(alloc, .{ start, end });
        }
    }

    ranges.items.len = collapseRanges(ranges.items) + 1;
    var rangeTotal: usize = 0;
    for (ranges.items) |range| {
        const len: usize = @intCast(range[1] - range[0]);
        rangeTotal += len;
    }
    rangeTotal -= beaconsOnRow.count();

    const distressSignal = for (0..@intCast(p2Size)) |r| {
        const row: i32 = @intCast(r);
        ranges.items.len = 0;
        for (sensors.items) |sensor| {
            const rowDist = @abs(sensor[1] - row);
            const dist: u32 = @intCast(sensor[2]);
            if (dist > rowDist) {
                const distToRow: i32 = @intCast(dist - rowDist);
                const start = @max(0, sensor[0] - distToRow);
                const end = @min(p2Size, sensor[0] + distToRow + 1);
                if (end >= start) try ranges.append(alloc, .{ start, end });
            }
        }

        const collapsed = collapseRanges(ranges.items);
        if (collapsed == 1) {
            const x: usize = @intCast(@max(ranges.items[0][0], ranges.items[1][0]) - 1);
            break x * 4_000_000 + r;
        }
    } else @panic("no solution found");

    return .{ rangeTotal, @intCast(distressSignal) };
}

fn collapseRanges(ranges: [][2]i32) usize {
    var i = ranges.len - 1;
    while (i > 0) : (i -%= 1) {
        const range = ranges[i];
        for (ranges[0..i]) |*otherRange| {
            if (range[0] <= otherRange[1] and range[1] >= otherRange[0]) {
                otherRange[0] = @min(range[0], otherRange[0]);
                otherRange[1] = @max(range[1], otherRange[1]);
                break;
            }
        } else {
            if (i > 1) {
                // will this always work?
                std.mem.swap([2]i32, &ranges[0], &ranges[i]);
                i += 1;
            } else return i;
        }
    }
    return 0;
}

test {
    const input =
        \\Sensor at x=2, y=18: closest beacon is at x=-2, y=15
        \\Sensor at x=9, y=16: closest beacon is at x=10, y=16
        \\Sensor at x=13, y=2: closest beacon is at x=15, y=3
        \\Sensor at x=12, y=14: closest beacon is at x=10, y=16
        \\Sensor at x=10, y=20: closest beacon is at x=10, y=16
        \\Sensor at x=14, y=17: closest beacon is at x=10, y=16
        \\Sensor at x=8, y=7: closest beacon is at x=2, y=10
        \\Sensor at x=2, y=0: closest beacon is at x=2, y=10
        \\Sensor at x=0, y=11: closest beacon is at x=2, y=10
        \\Sensor at x=20, y=14: closest beacon is at x=25, y=17
        \\Sensor at x=17, y=20: closest beacon is at x=21, y=22
        \\Sensor at x=16, y=7: closest beacon is at x=15, y=3
        \\Sensor at x=14, y=3: closest beacon is at x=15, y=3
        \\Sensor at x=20, y=1: closest beacon is at x=15, y=3
    ;
    const results = try solveParameterized(std.testing.allocator, input, 10, 20);
    try std.testing.expectEqual(26, results[0]);
    try std.testing.expectEqual(56000011, results[1]);
}
