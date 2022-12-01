const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const mostTotal = try mostTotalCalories(input);
    std.debug.print("most total: {}\n", .{mostTotal});

    const topThree = try topThreeCaloriesTotal(input);
    std.debug.print("top three total: {}\n", .{topThree});
}

fn mostTotalCalories(input: []const u8) !u32 {
    const buf = try mostTotalCaloriesTop(comptime 1, input);
    return buf[0];
}

fn topThreeCaloriesTotal(input: []const u8) !u32 {
    const buf = try mostTotalCaloriesTop(comptime 3, input);

    var total: u32 = 0;
    for (buf) |n| total += n;
    return total;
}

fn lineEmpty(line: ?[]const u8) bool {
    const l = line orelse return true;
    return l.len == 0;
}

fn mostTotalCaloriesTop(comptime N: usize, input: []const u8) ![N]u32 {
    var iter = std.mem.split(u8, input, "\n");

    var buf = [_]u32{0} ** (N + 1);
    var current: u32 = 0;

    while (true) {
        const line = iter.next();
        if (!lineEmpty(line)) {
            const amount = try std.fmt.parseInt(u32, line.?, 10);
            current += amount;
            continue;
        }
        buf[N] = current;
        std.sort.sort(u32, &buf, {}, comptime std.sort.desc(u32));

        if (line == null) break;
        current = 0;
    }

    var result: [N]u32 = undefined;
    std.mem.copy(u32, &result, buf[0..N]);
    return result;
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

    try std.testing.expectEqual(try topThreeCaloriesTotal(input), 45000);
}
