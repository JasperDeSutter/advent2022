const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("13", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;

    var lines = std.mem.split(u8, input, "\n");

    var correctlyOrderedPairs: usize = 0;

    for (1..std.math.maxInt(usize)) |i| {
        const up = lines.next() orelse unreachable;
        const down = lines.next() orelse break;

        if (cmp(up, down)) {
            correctlyOrderedPairs += i;
        }

        if (lines.next() == null) {
            break;
        }
    }

    return .{ correctlyOrderedPairs, 0 };
}

fn cmp(a: []const u8, b: []const u8) bool {
    const len = @min(a.len, b.len);
    var i: usize = 0;
    while (i < len and a[i] == b[i]) {
        i += 1;
    }
    if (i == a.len) return true;
    if (i == b.len) return false;

    if (a[i] == ']') {
        return true;
    }
    if (b[i] == ']') {
        return false;
    }

    if (a[i] == '[') {
        return skipStack(a[i..], b[i..]);
    }
    if (b[i] == '[') {
        return !skipStack(b[i..], a[i..]);
    }

    // numbers go up to 10
    if (a[i] < b[i]) {
        if (a[i] == '1' and a[i + 1] == '0') {
            return false;
        }
        return true;
    }
    if (b[i] == '1' and b[i + 1] == '0') {
        return true;
    }

    return false;
}

fn skipStack(stack: []const u8, num: []const u8) bool {
    // stack[0] is always '[', num[0] is always a digit

    var off: usize = 1;
    while (stack[off] == '[') {
        off += 1;
    }
    if (stack[off] == ']') return true; // stack closed first
    const a = stack[off..];
    const b = num;

    var size: usize = 1;
    if (a[0] != b[0]) {
        if (a[0] < b[0]) {
            if (a[0] == '1' and a[1] == '0') {
                return false;
            }
            return true;
        }
        if (b[0] == '1' and b[1] == '0') {
            return true;
        }
        return false;
    } else {
        if (a[0] == '1' and a[1] == '0') {
            if (b[1] != '0') return false;
            size += 1;
        }
    }

    for (a[size..]) |c| {
        if (c != ']') return false;
    }

    return cmp(a[off + size..], b[size..]);
}

test {
    const input =
        \\[1,1,3,1,1]
        \\[1,1,5,1,1]
        \\
        \\[[1],[2,3,4]]
        \\[[1],4]
        \\
        \\[9]
        \\[[8,7,6]]
        \\
        \\[[4,4],4,4]
        \\[[4,4],4,4,4]
        \\
        \\[7,7,7,7]
        \\[7,7,7]
        \\
        \\[]
        \\[3]
        \\
        \\[[[]]]
        \\[[]]
        \\
        \\[1,[2,[3,[4,[5,6,7]]]],8,9]
        \\[1,[2,[3,[4,[5,6,0]]]],8,9]
    ;
    const results = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(13, results[0]);
}
