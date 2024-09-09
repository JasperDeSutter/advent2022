const std = @import("std");
const builtin = @import("builtin");

fn read_file(alloc: std.mem.Allocator) ![]const u8 {
    var args_iter = try std.process.argsWithAllocator(alloc);
    defer args_iter.deinit();
    _ = args_iter.skip();
    const input_path = args_iter.next().?;

    const file = try std.fs.openFileAbsolute(input_path, .{});
    defer file.close();

    return file.readToEndAlloc(alloc, 10_000_000);
}

pub fn run(
    comptime day: []const u8,
    comptime solve: fn (
        alloc: std.mem.Allocator,
        input: []const u8,
    ) anyerror![2]usize,
) fn () anyerror!void {
    return struct {
        fn main() anyerror!void {
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer if (gpa.deinit() == .leak) @panic("leak");
            var alloc = gpa.allocator();

            const input = try read_file(alloc);
            defer alloc.free(input);
            // const input = @embedFile("inputdata/day" ++ day ++ ".txt");

            const start = std.time.nanoTimestamp();
            const result = try solve(alloc, input);
            const end = std.time.nanoTimestamp();

            std.debug.print("{s} part 1: {}\n{s} part 2: {}\nduration: {d}μs\n", .{ day, result[0], day, result[1], @divTrunc(end - start, 1000) });
        }
    }.main;
}
