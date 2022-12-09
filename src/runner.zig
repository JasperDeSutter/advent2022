const std = @import("std");
const builtin = @import("builtin");

pub fn run(
    comptime solve: fn (
        alloc: std.mem.Allocator,
        input: []const u8,
    ) anyerror!void,
) fn () anyerror!void {
    return struct {
        fn main() anyerror!void {
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer if (gpa.deinit()) @panic("leak");
            var alloc = gpa.allocator();

            var args_iter = try std.process.argsWithAllocator(alloc);
            defer args_iter.deinit();
            _ = args_iter.skip();
            const input_path = args_iter.next().?;

            const file = try std.fs.openFileAbsolute(input_path, .{});
            defer file.close();

            const input = try file.readToEndAlloc(alloc, 10_000_000);
            defer alloc.free(input);

            const start = std.time.nanoTimestamp();
            try solve(alloc, input);
            const end = std.time.nanoTimestamp();
            std.debug.print("duration: {d}us\n", .{@divTrunc(end - start, 1000)});
        }
    }.main;
}
