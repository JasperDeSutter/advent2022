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
    entries: std.ArrayList(Item),
    fn init(alloc: std.mem.Allocator) @This() {
        return .{
            .entries = std.ArrayList(Item).init(alloc),
        };
    }

    fn deinit(self: @This()) void {
        for (self.entries.items) |item| {
            switch (item) {
                .dir => |dir| dir.deinit(),
                else => {},
            }
        }
        self.entries.deinit();
    }

    fn print(self: *const @This()) void {
        std.debug.print("dir\n", .{});
        for (self.entries.items) |item| {
            switch (item) {
                .dir => |dir| dir.print(),
                .file => |file| std.debug.print("file: {any}\n", .{file.size}),
            }
        }
    }
};

const File = struct {
    size: u32,
};

const ItemType = enum {
    dir,
    file,
};

const Item = union(ItemType) {
    dir: Dir,
    file: File,
};

fn parseDirTree(alloc: std.mem.Allocator, input: []const u8) !Dir {
    var lines = std.mem.split(u8, input, "\n");

    var stack = std.ArrayList(*Dir).init(alloc);
    defer stack.deinit();

    _ = lines.next(); // $ cd /
    var root = Dir.init(alloc);
    try stack.append(&root);

    while (lines.next()) |line| {
        if (line[0] == '$') {
            const cmd = line[2..];
            if (std.mem.eql(u8, cmd, "ls")) continue;
            if (std.mem.startsWith(u8, cmd, "cd")) {
                const to = cmd[3..];
                if (std.mem.eql(u8, to, "..")) {
                    _ = stack.pop();
                } else {
                    var cd = stack.items[stack.items.len - 1];
                    var item = try cd.entries.addOne();
                    item.* = Item{ .dir = Dir.init(alloc) };
                    try stack.append(&item.dir);
                }
            } else @panic("unknown command!");
        } else {
            if (!std.mem.startsWith(u8, line, "dir")) {
                var cd = stack.items[stack.items.len - 1];
                var parts = std.mem.split(u8, line, " ");
                const sizePart = parts.next().?;
                const size = try std.fmt.parseInt(u32, sizePart, 10);
                try cd.entries.append(Item{ .file = File{ .size = size } });
            }
        }
    }

    return root;
}

fn inner(dir: *const Dir, result: *u32) u32 {
    var total: u32 = 0;
    for (dir.entries.items) |item| {
        total += switch (item) {
            .file => |file| file.size,
            .dir => |child| inner(&child, result),
        };
    }

    if (total <= 100_000) result.* += total;

    return total;
}

fn sumOfSmallDirectories(dirTree: *const Dir) u32 {
    var result: u32 = 0;
    for (dirTree.entries.items) |item| {
        _ = switch (item) {
            .dir => |dir| inner(&dir, &result),
            .file => {},
        };
    }
    return result;
}

fn smallestDirectoryToDeleteInner(dir: *const Dir, size: u32) u32 {
    var total: u32 = 0;
    for (dir.entries.items) |item| {
        switch (item) {
            .file => |file| total += file.size,
            .dir => |child| {
                const childSize = smallestDirectoryToDeleteInner(&child, size);
                if (childSize >= size) return childSize;
                total += childSize;
            },
        }
    }

    return total;
}

fn smallestDirectoryToDelete(dirTree: *const Dir) u32 {
    var unused: u32 = 0;
    const size = inner(dirTree, &unused);
    const free = 70000000 - size;
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
