const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("04", solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    const result = try fullyOverlappingAssignmentCount(input);
    return .{
        result.fullyOverlapping,
        result.partiallyOverlapping,
    };
}

const Error = error{ParsingError};

const Result = struct {
    fullyOverlapping: u32,
    partiallyOverlapping: u32,
};

fn parseNextPart(it: *std.mem.TokenIterator(u8, .any)) Error!u32 {
    const slice = it.next() orelse return Error.ParsingError;
    return std.fmt.parseInt(u32, slice, 10) catch return Error.ParsingError;
}

fn fullyOverlappingAssignmentCount(input: []const u8) Error!Result {
    var lines = std.mem.split(u8, input, "\n");
    var result = Result{ .fullyOverlapping = 0, .partiallyOverlapping = 0 };

    while (lines.next()) |line| {
        var parts = std.mem.tokenize(u8, line, "-,");

        const from1 = try parseNextPart(&parts);
        const to1 = try parseNextPart(&parts);
        const from2 = try parseNextPart(&parts);
        const to2 = try parseNextPart(&parts);

        if (from1 >= from2 and to1 <= to2 or from1 <= from2 and to1 >= to2) {
            result.fullyOverlapping += 1;
        }
        if (!(to1 < from2 or to2 < from1)) {
            result.partiallyOverlapping += 1;
        }
    }

    return result;
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

    const result = try fullyOverlappingAssignmentCount(input);
    try std.testing.expectEqual(result.fullyOverlapping, 2);
    try std.testing.expectEqual(result.partiallyOverlapping, 4);
}
