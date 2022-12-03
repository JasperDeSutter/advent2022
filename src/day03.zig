const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    std.debug.print("sum of wrong item priorities: {any}\n", .{sumOfWrongItemPriorities(input)});
}

fn sumOfWrongItemPriorities(input: []const u8) u32 {
    var lines = std.mem.split(u8, input, "\n");
    var sum: u32 = 0;
    outer: while (lines.next()) |line| {
        const firstHalf = line[0..(line.len / 2)];
        const secondHalf = line[(line.len / 2)..];

        for (secondHalf) |c| {
            for (firstHalf) |c2| {
                if (c == c2) {
                    if (c >= 'a' and c <= 'z') {
                        sum += (c - 'a') + 1;
                    } else {
                        sum += (c - 'A') + 27;
                    }
                    continue :outer;
                }
            }
        }
    }
    return sum;
}

test {
    const input =
        \\vJrwpWtwJgWrhcsFMMfFFhFp
        \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
        \\PmmdzqPrVvPwwTWBwg
        \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
        \\ttgJtRGJQctTZtZT
        \\CrZsJsPPZsGzwwsLwLmpwMDw
    ;

    try std.testing.expectEqual(sumOfWrongItemPriorities(input), 157);
}
