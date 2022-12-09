const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const dirTree = try parseSortedDirSizes(alloc, input);
    defer dirTree.deinit();

    std.debug.print("sumOfSmallDirectories: {any}\n", .{sumOfSmallDirectories(dirTree.items)});
    std.debug.print("smallestDirectoryToDelete: {any}\n", .{smallestDirectoryToDelete(dirTree.items)});
}

fn parseDirSize(lines: *std.mem.SplitIterator(u8), sizes: *std.ArrayList(u32)) !u32 {
    var totalSize: u32 = 0;

    while (lines.next()) |line| {
        if (line[0] == '$') {
            const cmd = line[2..];
            if (std.mem.eql(u8, cmd, "ls")) continue;
            if (std.mem.startsWith(u8, cmd, "cd")) {
                const to = cmd[3..];
                if (std.mem.eql(u8, to, "..")) {
                    return totalSize;
                } else {
                    const child = try parseDirSize(lines, sizes);
                    totalSize += child;
                    try sizes.append(child);
                }
            } else @panic("unknown command!");
        } else {
            if (!std.mem.startsWith(u8, line, "dir")) {
                var parts = std.mem.split(u8, line, " ");
                const sizePart = parts.next().?;
                const size = try std.fmt.parseInt(u32, sizePart, 10);
                totalSize += size;
            }
        }
    }
    return totalSize;
}

fn parseSortedDirSizes(alloc: std.mem.Allocator, input: []const u8) !std.ArrayList(u32) {
    var lines = std.mem.split(u8, input, "\n");
    var sizes = std.ArrayList(u32).init(alloc);

    _ = try parseDirSize(&lines, &sizes);
    std.sort.sort(u32, sizes.items, {}, std.sort.desc(u32));
    return sizes;
}

fn findLastGreaterThan(key: u32, items: []const u32) usize {
    var left: usize = 0;
    var right: usize = items.len;

    while (left < right) {
        const mid = left + (right - left) / 2;
        if (items[mid] > key) {
            left = mid + 1;
        } else {
            right = mid;
        }
    }

    return right;
}

fn sumOfSmallDirectories(dirSizes: []const u32) !u32 {
    const i = findLastGreaterThan(100_000, dirSizes);

    var result: u32 = 0;
    for (dirSizes[i..]) |dir| {
        result += dir;
    }
    return result;
}

fn smallestDirectoryToDelete(dirSizes: []const u32) u32 {
    const free = 70000000 - dirSizes[0];
    const i = findLastGreaterThan(30000000 - free, dirSizes);
    return dirSizes[i - 1];
}

test {
    const input =
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    ;

    const dirTree = try parseSortedDirSizes(std.testing.allocator, input);
    defer dirTree.deinit();

    try std.testing.expectEqual(sumOfSmallDirectories(dirTree.items), 95437);
    try std.testing.expectEqual(smallestDirectoryToDelete(dirTree.items), 24933642);
}
