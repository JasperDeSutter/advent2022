const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const mostTotal = try mostTotalCalories(input);
    std.debug.print("most total: {}\n", .{mostTotal});
}

fn mostTotalCalories(input: []const u8) !u32 {
    var iter = std.mem.split(u8, input, "\n");
    var most: u32 = 0;
    var current: u32 = 0;

    while (iter.next()) |line| {
        if (line.len == 0) {
            if (current > most) most = current;
            current = 0;
            continue;
        }
        const amount = try std.fmt.parseInt(u32, line, 10);
        current += amount;
    }

    return most;
}

test {
    const input =
        \\1000
        \\2000
        \\3000
        \\
        \\4000
        \\
        \\5000
        \\6000
        \\
        \\7000
        \\8000
        \\9000
        \\
        \\10000
    ;

    try std.testing.expectEqual(try mostTotalCalories(input), 24000);
}
