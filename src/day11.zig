const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("11", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    const score1 = b1: {
        var game = try parseGame(alloc, input);
        defer game.deinit();
        break :b1 try game.monkeyBusinessLevel(false);
    };
    var game = try parseGame(alloc, input);
    defer game.deinit();
    const score2 = try game.monkeyBusinessLevel(true);

    return .{
        score1,
        score2,
    };
}

const Monkey = struct {
    items: std.ArrayList(u32),
    add: u8 = 0,
    mul: u8 = 0,
    mulSelf: u8 = 0,
    testBy: u8 = 0,
    throwTo: [2]u8 = .{ 0, 0 },
    inspections: usize = 0,
};

const Game = struct {
    monkeys: std.ArrayList(Monkey),
    supermod: u32,

    fn init(monkeys: std.ArrayList(Monkey)) @This() {
        var supermod: u32 = 1;
        for (monkeys.items) |monkey| {
            supermod *= monkey.testBy;
        }

        return .{
            .monkeys = monkeys,
            .supermod = supermod,
        };
    }

    fn round(self: *@This(), comptime worry: bool) void {
        var i: usize = 0;
        while (i < self.monkeys.items.len) : (i += 1) {
            var monkey = &self.monkeys.items[i];
            monkey.inspections += monkey.items.items.len;
            const items = monkey.items.items;
            for (items) |item| {
                var value: u64 = item;
                value = (value * (monkey.mul + value * monkey.mulSelf)) + monkey.add;
                if (!worry) {
                    value /= 3;
                }
                const setValue: u32 = @intCast(value % self.supermod);
                const to = monkey.throwTo[@intFromBool(value % monkey.testBy == 0)];
                self.monkeys.items[to].items.appendAssumeCapacity(setValue);
            }
            monkey.items.items.len = 0;
        }
    }

    fn monkeyBusinessLevel(self: *@This(), comptime worry: bool) !usize {
        var i: usize = 0;
        var rounds: usize = 20;
        if (worry) rounds = 10_000;
        while (i < rounds) : (i += 1) {
            self.round(worry);
        }

        var inspections = std.ArrayList(usize).init(self.monkeys.allocator);
        defer inspections.deinit();
        i = 0;
        while (i < self.monkeys.items.len) : (i += 1) {
            try inspections.append(self.monkeys.items[i].inspections);
            self.monkeys.items[i].inspections = 0;
        }
        std.mem.sortUnstable(usize, inspections.items, {}, std.sort.desc(usize));
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
    var totalItems: u8 = 0;
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
                    totalItems += 1;
                }
                continue;
            }
            if (part[0] == 'O') {
                part = part["Operation: new = old ".len..];
                const operand = std.fmt.parseInt(u8, part[2..], 10) catch {
                    monkey.mulSelf = 1;
                    continue;
                };

                if (part[0] == '*') {
                    monkey.mul = operand;
                } else {
                    monkey.add = operand;
                    monkey.mul = 1;
                }

                continue;
            }
            if (part[0] == 'T') {
                part = part["Test: divisible by ".len..];
                monkey.testBy = try std.fmt.parseInt(u8, part, 10);
                continue;
            }
            @panic("unexpected input");
        }
        const new: Monkey = .{ .items = std.ArrayList(u32).init(alloc) };
        try monkeys.append(new);
    }

    var i: u8 = 0;
    while (i < monkeys.items.len) : (i += 1) {
        try monkeys.items[i].items.ensureTotalCapacity(totalItems);
    }

    return Game.init(monkeys);
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

    {
        var game = try parseGame(std.testing.allocator, input);
        defer game.deinit();
        const score = try game.monkeyBusinessLevel(false);
        try std.testing.expectEqual(score, 10605);
    }
    {
        var game = try parseGame(std.testing.allocator, input);
        defer game.deinit();
        const score2 = try game.monkeyBusinessLevel(true);
        try std.testing.expectEqual(score2, 2713310158);
    }
}
