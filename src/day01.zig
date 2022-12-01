const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(_: std.mem.Allocator, _: []const u8) anyerror!void {
    
}

test {
    const input =
    \\
    ;
    _ = input;
}
