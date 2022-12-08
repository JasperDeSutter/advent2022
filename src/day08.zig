const std = @import("std");
const runner = @import("runner.zig");

pub fn main() anyerror!void {
    try runner.run(solve);
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try treeCheck(alloc, input);
    std.debug.print("visibleTreeCount: {any}\n", .{result.visibleTreeCount});
    std.debug.print("highestScenicScore: {any}\n", .{result.highestScenicScore});
}

const Result = struct {
    visibleTreeCount: u32,
    highestScenicScore: u32,
};

const State = struct {
    width: usize,
    height: usize,
    markers: []bool,
    alloc: std.mem.Allocator,

    highest: u8 = 0,
    history: std.ArrayListUnmanaged(u8),
    direction: u8 = 0,
    scenicScores: std.ArrayListUnmanaged(std.ArrayListUnmanaged(u8)),

    fn init(allocator: std.mem.Allocator, widthArg: usize, heightArg: usize) !@This() {
        const count = heightArg * widthArg;
        const markers = try allocator.alloc(bool, count);

        var scores = try std.ArrayListUnmanaged(std.ArrayListUnmanaged(u8)).initCapacity(allocator, 4);
        var dir: u8 = 0;
        while (dir < 4) : (dir += 1) {
            var board = try std.ArrayListUnmanaged(u8).initCapacity(allocator, count);
            board.appendNTimesAssumeCapacity(0, count);
            scores.appendAssumeCapacity(board);
        }

        const historySize = std.math.max(widthArg, heightArg);
        return .{
            .markers = markers,
            .width = widthArg,
            .height = heightArg,
            .alloc = allocator,
            .history = try std.ArrayListUnmanaged(u8).initCapacity(allocator, historySize),
            .scenicScores = scores,
        };
    }

    fn deinit(self: *@This()) void {
        self.alloc.free(self.markers);
        self.history.deinit(self.alloc);
        var i: usize = 0;
        while (i < self.scenicScores.items.len) : (i += 1) {
            var scores = &self.scenicScores.items[i];
            scores.deinit(self.alloc);
        }
        self.scenicScores.deinit(self.alloc);
    }

    fn checkTree(self: *@This(), tree: u8, x: usize, y: usize) void {
        if (tree > self.highest) {
            self.markers[y * self.width + x] = true;
            self.highest = tree;
        }

        const historyLen = self.history.items.len;
        if (historyLen > 0) {
            var i = historyLen - 1;
            while (i > 0) : (i -= 1) {
                var h = self.history.items[i];
                if (h >= tree) {
                    const score = @intCast(u8, historyLen - i);
                    self.scenicScores.items[self.direction].items[y * self.height + x] = score;
                    break;
                }
            }
            if (i == 0) {
                self.scenicScores.items[self.direction].items[y * self.height + x] = @intCast(u8, historyLen);
            }
        }

        self.history.appendAssumeCapacity(tree);
    }

    fn resetDirection(self: *@This(), direction: u8) void {
        self.highest = 0;
        self.history.items.len = 0;
        self.direction = direction;
    }

    fn result(self: *const @This()) Result {
        var totalVisible: u32 = 0;
        for (self.markers) |marker| {
            if (marker) totalVisible += 1;
        }

        var highestScore: u32 = 0;

        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                var dir: usize = 0;
                var score: u32 = 1;
                while (dir < 4) : (dir += 1) {
                    score *= self.scenicScores.items[dir].items[y * self.height + x];
                }
                if (score > highestScore) highestScore = score;
            }
        }

        return Result{
            .visibleTreeCount = totalVisible,
            .highestScenicScore = highestScore,
        };
    }
};

fn treeCheck(alloc: std.mem.Allocator, input: []const u8) !Result {
    var rows = std.ArrayList([]const u8).init(alloc);
    defer rows.deinit();
    {
        var lines = std.mem.split(u8, input, "\n");
        while (lines.next()) |line| try rows.append(line);
    }

    const width = rows.items[0].len;
    const height = rows.items.len;

    var state = try State.init(alloc, width, height);
    defer state.deinit();

    for (rows.items) |row, y| {
        state.resetDirection(0);
        var x: usize = 0;
        while (x < width) : (x += 1) {
            const tree = rows.items[y][x];
            state.checkTree(tree, x, y);
        }

        state.resetDirection(1);
        x = row.len - 1;
        while (x > 0) : (x -= 1) {
            const tree = row[x];
            state.checkTree(tree, x, y);
        }
    }

    {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            state.resetDirection(2);
            var y: usize = 0;
            while (y < height) : (y += 1) {
                const tree = rows.items[y][x];
                state.checkTree(tree, x, y);
            }

            state.resetDirection(3);
            y = height - 1;
            while (y > 0) : (y -= 1) {
                const tree = rows.items[y][x];
                state.checkTree(tree, x, y);
            }
        }
    }
    return state.result();
}

test {
    const input =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;

    const result = try treeCheck(std.testing.allocator, input);
    try std.testing.expectEqual(result.visibleTreeCount, 21);
    try std.testing.expectEqual(result.highestScenicScore, 8);
}
