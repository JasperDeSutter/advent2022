const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    _ = alloc;

    std.debug.print("firstStartOfPacketMarker: {any}\n", .{firstStartOfPacketMarker(input)});
}

fn RingBuffer(comptime T: type, comptime size: u8) type {
    return struct {
        i: u8 = 0,
        buf: [size]T = [1]T{0} ** size,

        fn setNext(self: *@This(), value: T) void {
            self.buf[self.i] = value;
            self.i = (self.i + 1) % size;
        }

        fn allDifferent(self: *const @This()) bool {
            for (self.buf[1..]) |v, i| {
                for (self.buf[0..(i + 1)]) |v2| {
                    if (v2 == v) return false;
                }
            }
            return true;
        }
    };
}

fn firstStartOfPacketMarker(datastream: []const u8) usize {
    var ringBuffer = RingBuffer(u8, 4){};
    for (datastream) |c, i| {
        ringBuffer.setNext(c);
        if (i > 2 and ringBuffer.allDifferent()) {
            return i + 1;
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
}
