const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const dirTree = try parseDirTree(alloc, input);
    defer dirTree.deinit();

    std.debug.print("sumOfSmallDirectories: {any}\n", .{sumOfSmallDirectories(&dirTree)});
    std.debug.print("smallestDirectoryToDelete: {any}\n", .{smallestDirectoryToDelete(&dirTree)});
}

const Dir = struct {
    entries: std.ArrayList(Dir),
    totalSize: u32 = 0,
    fn init(alloc: std.mem.Allocator) @This() {
        return .{
            .entries = std.ArrayList(Dir).init(alloc),
        };
    }

    fn deinit(self: @This()) void {
        for (self.entries.items) |item| {
            item.deinit();
        }
        self.entries.deinit();
    }

    fn print(self: *const @This()) void {
        std.debug.print("dir: {any}\n", .{self.totalSize});
        for (self.entries.items) |item| {
            item.print();
        }
    }
};

fn parseDir(alloc: std.mem.Allocator, lines: *std.mem.SplitIterator(u8)) !Dir {
    var dir = Dir.init(alloc);

    while (lines.next()) |line| {
        if (line[0] == '$') {
            const cmd = line[2..];
            if (std.mem.eql(u8, cmd, "ls")) continue;
            if (std.mem.startsWith(u8, cmd, "cd")) {
                const to = cmd[3..];
                if (std.mem.eql(u8, to, "..")) {
                    return dir;
                } else {
                    const child = try parseDir(alloc, lines);
                    dir.totalSize += child.totalSize;
                    try dir.entries.append(child);
                }
            } else @panic("unknown command!");
        } else {
            if (!std.mem.startsWith(u8, line, "dir")) {
                var parts = std.mem.split(u8, line, " ");
                const sizePart = parts.next().?;
                const size = try std.fmt.parseInt(u32, sizePart, 10);
                dir.totalSize += size;
            }
        }
    }
    return dir;
}

fn parseDirTree(alloc: std.mem.Allocator, input: []const u8) !Dir {
    var lines = std.mem.split(u8, input, "\n");

    _ = lines.next(); // $ cd /
    return try parseDir(alloc, &lines);
}

fn sumOfSmallDirectories(dirTree: *const Dir) u32 {
    var result: u32 = 0;
    for (dirTree.entries.items) |dir| {
        if (dir.totalSize < 100_000) result += dir.totalSize;
        result += sumOfSmallDirectories(&dir);
    }
    return result;
}

fn smallestDirectoryToDeleteInner(dir: *const Dir, size: u32) u32 {
    for (dir.entries.items) |child| {
        if (child.totalSize < size) continue;
        return smallestDirectoryToDeleteInner(&child, size);
    }
    return dir.totalSize;
}

fn smallestDirectoryToDelete(dirTree: *const Dir) u32 {
    const free = 70000000 - dirTree.totalSize;
    return smallestDirectoryToDeleteInner(dirTree, 30000000 - free);
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

    const dirTree = try parseDirTree(std.testing.allocator, input);
    defer dirTree.deinit();

    try std.testing.expectEqual(sumOfSmallDirectories(&dirTree), 95437);
    try std.testing.expectEqual(smallestDirectoryToDelete(&dirTree), 24933642);
}
