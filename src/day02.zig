const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("02", solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    return .{
        calculateScore(input, chooseMove1),
        calculateScore(input, chooseMove2),
    };
}

fn chooseMove1(other: u8, hint: u8) u8 {
    _ = other;
    return hint;
}

fn chooseMove2(other: u8, hint: u8) u8 {
    if (hint == 0) {
        const wrapped = other -% 1;
        if (wrapped > 2) return wrapped - 253;
        return wrapped;
    }
    if (hint == 2) return (other +% 1) % 3;
    return other;
}

fn calculateScore(input: []const u8, chooseMove: anytype) u32 {
    var lines = std.mem.split(u8, input, "\n");
    var score: u32 = 0;
    while (lines.next()) |line| {
        const opponent = line[0] - 'A';
        const me = chooseMove(opponent, line[2] - 'X');

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

    try std.testing.expectEqual(calculateScore(input, chooseMove1), 15);
    try std.testing.expectEqual(calculateScore(input, chooseMove2), 12);
}
