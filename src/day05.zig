const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("05", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var stackResult = try stackCrates(alloc, input, false);
    defer stackResult.deinit();
    std.debug.print("stackResult: {s}\n", .{stackResult.items});

    var orderedStackResult = try stackCrates(alloc, input, true);
    defer orderedStackResult.deinit();
    std.debug.print("stackResult: {s}\n", .{orderedStackResult.items});

    return .{
        0, //stackResult.items,
        0, //orderedStackResult.items,
    };
}

const Stack = std.ArrayList(u8);

fn stackCrates(alloc: std.mem.Allocator, input: []const u8, inOrder: bool) anyerror!std.ArrayList(u8) {
    var lines = std.mem.split(u8, input, "\n");

    var stacks = std.ArrayList(Stack).init(alloc);
    defer {
        for (stacks.items) |stack| {
            stack.deinit();
        }
        stacks.deinit();
    }

    var line = lines.next().?;
    while (line.len > 0) {
        var i: usize = 0;
        while (line.len > 0) {
            if (line[0] == '[') {
                const letter = line[1];
                while (stacks.items.len < (i + 1)) {
                    try stacks.append(Stack.init(alloc));
                }

                var stack: *Stack = &stacks.items[i];
                try stack.append(letter);
            }

            if (line.len < 4) break;
            line = line[4..];
            i += 1;
        }
        line = lines.next().?;
    }

    for (stacks.items) |stack| {
        std.mem.reverse(u8, stack.items);
    }

    while (lines.next()) |l| {
        var parts = std.mem.split(u8, l, " ");
        _ = parts.next();
        const count = try std.fmt.parseInt(u32, parts.next().?, 10);
        _ = parts.next();
        const from = try std.fmt.parseInt(u32, parts.next().?, 10);
        _ = parts.next();
        const to = try std.fmt.parseInt(u32, parts.next().?, 10);

        var fromStack: *Stack = &stacks.items[from - 1];
        var toStack: *Stack = &stacks.items[to - 1];

        {
            const slice = fromStack.items[fromStack.items.len - count ..];
            if (!inOrder) std.mem.reverse(u8, slice);
            try toStack.appendSlice(slice);
            fromStack.items.len -= count;
        }
    }

    var result = try std.ArrayList(u8).initCapacity(alloc, stacks.items.len);
    errdefer result.deinit();

    for (stacks.items) |stack| {
        const firstLetter = stack.items[stack.items.len - 1];
        try result.append(firstLetter);
    }

    return result;
}

test {
    const input =
        \\    [D]    
        \\[N] [C]    
        \\[Z] [M] [P]
        \\ 1   2   3 
        \\
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
    ;

    const result1 = try stackCrates(std.testing.allocator, input, false);
    defer result1.deinit();
    try std.testing.expectEqualStrings("CMZ", result1.items);

    const result2 = try stackCrates(std.testing.allocator, input, true);
    defer result2.deinit();
    try std.testing.expectEqualStrings("MCD", result2.items);
}
