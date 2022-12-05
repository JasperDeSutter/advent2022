const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    var stackResult = try stackCrates(alloc, input);
    defer stackResult.deinit();
    std.debug.print("stackResult: {s}\n", .{stackResult.items});
}

const Stack = std.ArrayList(u8);

fn stackCrates(alloc: std.mem.Allocator, input: []const u8) anyerror!std.ArrayList(u8) {
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
        var count = try std.fmt.parseInt(u8, parts.next().?, 10);
        _ = parts.next();
        const from = try std.fmt.parseInt(u8, parts.next().?, 10);
        _ = parts.next();
        const to = try std.fmt.parseInt(u8, parts.next().?, 10);

        var fromStack = &stacks.items[from - 1];
        var toStack = &stacks.items[to - 1];

        while (count > 0) : (count -= 1) {
            var ptr = try toStack.addOne();
            ptr.* = fromStack.pop();
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

    const result = try stackCrates(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expectEqualStrings("CMZ", result.items);
}
