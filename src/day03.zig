const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    std.debug.print("sum of wrong item priorities: {any}\n", .{sumOfWrongItemPriorities(input)});
    std.debug.print("sum of wrong badge priorities: {any}\n", .{sumOfBadgePriorities(input)});
}

fn priority(char: u8) u32 {
    if (char >= 'a') {
        return (char - 'a') + 1;
    } else {
        return (char - 'A') + 27;
    }
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
                    sum += priority(c);
                    continue :outer;
                }
            }
        }
    }
    return sum;
}

const CharMap = struct {
    values: ['z' - 'A' + 1]u8 = [1]u8{0} ** ('z' - 'A' + 1),
    fn set(self: *@This(), char: u8, value: u8) void {
        self.values[char - 'A'] = value;
    }

    fn get(self: *const @This(), char: u8) u8 {
        return self.values[char - 'A'];
    }

    fn combine(self: *@This(), other: *const @This()) void {
        for (other.values) |v, i| {
            self.values[i] += v;
        }
    }
};

fn sumOfBadgePriorities(input: []const u8) u32 {
    var lines = std.mem.split(u8, input, "\n");
    var sum: u32 = 0;
    outer: while (true) {
        var combinedMap = CharMap{};
        comptime var group: u8 = 0;
        inline while (group < (3 - 1)) : (group += 1) {
            const line = lines.next() orelse break :outer;
            var map = CharMap{};
            for (line) |c| {
                map.set(c, 1);
            }
            combinedMap.combine(&map);
        }

        {
            const line = lines.next() orelse break :outer;
            for (line) |c| {
                if (combinedMap.get(c) == 2) {
                    sum += priority(c);
                    break;
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
    try std.testing.expectEqual(sumOfBadgePriorities(input), 70);
}
