const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("06", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;

    return .{
        firstStartOfPacketMarker(input),
        firstStartOfMessageMarker(input),
    };
}

fn firstStartOfPacketMarker(datastream: []const u8) usize {
    return impl(datastream, 4);
}

fn firstStartOfMessageMarker(datastream: []const u8) usize {
    return impl(datastream, 14);
}

fn impl(datastream: []const u8, size: u8) usize {
    var slice: []const u8 = datastream[0..1];
    for (datastream[1..], 0..) |c, end| {
        for (slice, 0..) |c2, i| {
            if (c2 == c) {
                slice = slice[(i + 1)..];
                break;
            }
        }
        slice.len += 1;
        if (slice.len == size) {
            return end + 2;
        }
    }
    return 0;
}

test {
    try std.testing.expectEqual(firstStartOfPacketMarker("mjqjpqmgbljsphdztnvjfqwrcgsmlb"), 7);
    try std.testing.expectEqual(firstStartOfPacketMarker("bvwbjplbgvbhsrlpgdmjqwftvncz"), 5);
    try std.testing.expectEqual(firstStartOfPacketMarker("nppdvjthqldpwncqszvftbrmjlhg"), 6);
    try std.testing.expectEqual(firstStartOfPacketMarker("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg"), 10);
    try std.testing.expectEqual(firstStartOfPacketMarker("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw"), 11);

    try std.testing.expectEqual(firstStartOfMessageMarker("mjqjpqmgbljsphdztnvjfqwrcgsmlb"), 19);
    try std.testing.expectEqual(firstStartOfMessageMarker("bvwbjplbgvbhsrlpgdmjqwftvncz"), 23);
    try std.testing.expectEqual(firstStartOfMessageMarker("nppdvjthqldpwncqszvftbrmjlhg"), 23);
    try std.testing.expectEqual(firstStartOfMessageMarker("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg"), 29);
    try std.testing.expectEqual(firstStartOfMessageMarker("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw"), 26);
}
