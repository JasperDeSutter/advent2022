const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const score = calculateScore(input);
    std.debug.print("score: {any}\n", .{score});
}

fn calculateScore(input: []const u8) u32 {
    var lines = std.mem.split(u8, input, "\n");
    var score: u32 = 0;
    while (lines.next()) |line| {
        const opponent = line[0] - 'A';
        const me = line[2] - 'X';

        const result = opponent -% me;
        const roundScore: u32 = switch (result) {
            255, 2 => 6,
            1, 254 => 0,
            else => 3,
        };

        score += me + 1;
        score += roundScore;
    }
    return score;
}

test {
    const input =
        \\A Y
        \\B X
        \\C Z
    ;

    try std.testing.expectEqual(calculateScore(input), 15);
}
