const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const mostTotal = try mostTotalCalories(input);
    std.debug.print("most total: {}\n", .{mostTotal});

    const topThree = try topThreeCaloriesTotal(input);
    std.debug.print("top three total: {}\n", .{topThree});
}

fn mostTotalCalories(input: []const u8) !u32 {
    var buf = [1]u32{0};
    try mostTotalCaloriesTop(&buf, input);
    return buf[0];
}

fn topThreeCaloriesTotal(input: []const u8) !u32 {
    var buf = [1]u32{0} ** 3;
    try mostTotalCaloriesTop(&buf, input);

    var total: u32 = 0;
    for (buf) |n| total += n;
    return total;
}

fn lineEmpty(line: ?[]const u8) bool {
    const l = line orelse return true;
    return l.len == 0;
}

fn push_front_slice(slice: []u32, n: u32) void {
    std.mem.copyBackwards(u32, slice[1..], slice[0..(slice.len - 1)]);
    slice[0] = n;
}

fn mostTotalCaloriesTop(buf: []u32, input: []const u8) !void {
    var iter = std.mem.split(u8, input, "\n");
    var current: u32 = 0;

    while (true) {
        const line = iter.next();
        if (!lineEmpty(line)) {
            const amount = try std.fmt.parseInt(u32, line.?, 10);
            current += amount;
            continue;
        }

        for (buf) |n, i| {
            if (n > current) continue;
            push_front_slice(buf[i..], current);
            break;
        }

        if (line == null) break;
        current = 0;
    }
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
