const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    var game = try parseGame(alloc, input);
    defer game.deinit();
    const score = try game.monkeyBusinessLevel();
    std.debug.print("monkey business: {any}\n", .{score});
}

const Monkey = struct {
    items: std.ArrayList(u16),
    operatorMul: bool = false,
    operand: u16 = 0,
    testBy: u16 = 0,
    throwTo: [2]u8 = .{ 0, 0 },
    inspections: usize = 0,
};

const Game = struct {
    monkeys: std.ArrayList(Monkey),

    fn round(self: *@This()) !void {
        var i: usize = 0;
        while (i < self.monkeys.items.len) : (i += 1) {
            var monkey = &self.monkeys.items[i];
            monkey.inspections += monkey.items.items.len;
            std.mem.reverse(u16, monkey.items.items);
            while (monkey.items.popOrNull()) |item| {
                var value: u32 = item;
                var with = value;
                if (monkey.operand != 0) with = monkey.operand;
                if (monkey.operatorMul) {
                    value *= with;
                } else {
                    value += with;
                }
                value /= 3;

                const index = @boolToInt(value % monkey.testBy == 0);
                const to = monkey.throwTo[index];
                try self.monkeys.items[to].items.append(@intCast(u16, value));
            }
        }
    }

    fn monkeyBusinessLevel(self: *@This()) !usize {
        var i: u8 = 0;
        while (i < 20) : (i += 1) {
            try self.round();
        }

        var inspections = std.ArrayList(usize).init(self.monkeys.allocator);
        defer inspections.deinit();
        i = 0;
        while (i < self.monkeys.items.len) : (i += 1) {
            try inspections.append(self.monkeys.items[i].inspections);
        }
        std.sort.sort(usize, inspections.items, {}, std.sort.desc(usize));
        return inspections.items[0] * inspections.items[1];
    }

    fn deinit(self: @This()) void {
        for (self.monkeys.items) |monkey| monkey.items.deinit();
        self.monkeys.deinit();
    }
};

fn parseGame(alloc: std.mem.Allocator, input: []const u8) !Game {
    var lines = std.mem.split(u8, input, "\n");
    var monkeys = std.ArrayList(Monkey).init(alloc);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] == ' ') {
            var part = line[2..];
            var monkey = &monkeys.items[monkeys.items.len - 1];
            if (part[0] == ' ') {
                if (part["  If ".len] == 't') {
                    const to = try std.fmt.parseInt(u8, part["  If true: throw to monkey ".len..], 10);
                    monkey.throwTo[1] = to;
                } else {
                    const to = try std.fmt.parseInt(u8, part["  If false: throw to monkey ".len..], 10);
                    monkey.throwTo[0] = to;
                }
                continue;
            }
            if (part[0] == 'S') {
                part = part["Starting items: ".len..];
                var items = std.mem.tokenize(u8, part, ", ");
                while (items.next()) |item| {
                    const n = try std.fmt.parseInt(u16, item, 10);
                    try monkey.items.append(n);
                }
                continue;
            }
            if (part[0] == 'O') {
                part = part["Operation: new = old ".len..];
                monkey.operatorMul = part[0] == '*';
                monkey.operand = std.fmt.parseInt(u16, part[2..], 10) catch 0;
                continue;
            }
            if (part[0] == 'T') {
                part = part["Test: divisible by ".len..];
                monkey.testBy = try std.fmt.parseInt(u16, part, 10);
                continue;
            }
            @panic("unexpected input");
        }
        const new: Monkey = .{ .items = std.ArrayList(u16).init(alloc) };
        try monkeys.append(new);
    }

    return Game{ .monkeys = monkeys };
}

test {
    const input =
        \\Monkey 0:
        \\  Starting items: 79, 98
        \\  Operation: new = old * 19
        \\  Test: divisible by 23
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 3
        \\
        \\Monkey 1:
        \\  Starting items: 54, 65, 75, 74
        \\  Operation: new = old + 6
        \\  Test: divisible by 19
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 0
        \\
        \\Monkey 2:
        \\  Starting items: 79, 60, 97
        \\  Operation: new = old * old
        \\  Test: divisible by 13
        \\    If true: throw to monkey 1
        \\    If false: throw to monkey 3
        \\
        \\Monkey 3:
        \\  Starting items: 74
        \\  Operation: new = old + 3
        \\  Test: divisible by 17
        \\    If true: throw to monkey 0
        \\    If false: throw to monkey 1
    ;

    var game = try parseGame(std.testing.allocator, input);
    defer game.deinit();
    const score = try game.monkeyBusinessLevel();
    try std.testing.expectEqual(score, 10605);
}
