const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("15", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    return .{ try rowSpotsOccupied(alloc, input, 2_000_000), 0 };
}

fn rowSpotsOccupied(alloc: std.mem.Allocator, input: []const u8, row: i32) anyerror!usize {
    var beaconsOnRow = std.AutoHashMapUnmanaged(i32, void){};
    defer beaconsOnRow.deinit(alloc);

    var startRange: i32 = std.math.maxInt(i32);
    var endRange: i32 = 0;

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

        const rowDist = @abs(sensorY - row);
        if (distance > rowDist) {
            if (sensorY == row) {
                try beaconsOnRow.put(alloc, sensorX, {});
            }
            if (beaconY == row) {
                try beaconsOnRow.put(alloc, beaconX, {});
            }
            const distToRow: i32 = @intCast(distance - rowDist);
            const start = sensorX - distToRow;
            if (start < startRange) startRange = start;
            const end = sensorX + distToRow;
            if (end > endRange) endRange = end;
        }
    }

    const rangeTotal: usize = @intCast(endRange - startRange);

    return rangeTotal - beaconsOnRow.count() + 1;
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
    const result1 = try rowSpotsOccupied(std.testing.allocator, input, 10);
    try std.testing.expectEqual(26, result1);
    // try std.testing.expectEqual(93, results[1]);
}
