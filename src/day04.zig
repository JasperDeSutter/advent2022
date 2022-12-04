const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    std.debug.print("fully overlapping assignment count: {any}\n", .{try fullyOverlappingAssignmentCount(input)});
}

const Error = error{ParsingError};

fn parseNextPart(it: *std.mem.TokenIterator(u8)) Error!u32 {
    const slice = it.next() orelse return Error.ParsingError;
    return std.fmt.parseInt(u32, slice, 10) catch return Error.ParsingError;
}

fn fullyOverlappingAssignmentCount(input: []const u8) Error!u32 {
    var lines = std.mem.split(u8, input, "\n");
    var total: u32 = 0;

    while (lines.next()) |line| {
        var parts = std.mem.tokenize(u8, line, "-,");
        const from1 = try parseNextPart(&parts);
        const to1 = try parseNextPart(&parts);
        const from2 = try parseNextPart(&parts);
        const to2 = try parseNextPart(&parts);

        if (from1 >= from2 and to1 <= to2) {
            total += 1;
        } else if (from1 <= from2 and to1 >= to2) {
            total += 1;
        }
    }

    return total;
}

test {
    const input =
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
    ;

    try std.testing.expectEqual(try fullyOverlappingAssignmentCount(input), 2);
}
