const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("08", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    const result = try treeCheck(alloc, input);

    return .{
        result.visibleTreeCount,
        result.highestScenicScore,
    };
}

const Result = struct {
    visibleTreeCount: usize,
    highestScenicScore: u32,
};

const State = struct {
    width: usize,
    height: usize,
    markers: std.DynamicBitSetUnmanaged,
    alloc: std.mem.Allocator,

    highest: u8 = 0,
    historyIndex: usize,
    history: []u8,
    scenicScores: []u32,

    fn init(allocator: std.mem.Allocator, widthArg: usize, heightArg: usize) !@This() {
        const count = heightArg * widthArg;
        const markers = try std.DynamicBitSetUnmanaged.initEmpty(allocator, count); // try allocator.alloc(bool, count);
        const scores = try allocator.alloc(u32, count);
        @memset(scores, 1);
        const historySize = @max(widthArg, heightArg);
        const history = try allocator.alloc(u8, historySize);

        return .{
            .markers = markers,
            .width = widthArg,
            .height = heightArg,
            .alloc = allocator,
            .history = history,
            .scenicScores = scores,
            .historyIndex = history.len,
        };
    }

    fn deinit(self: *@This()) void {
        self.markers.deinit(self.alloc);
        self.alloc.free(self.history);
        self.alloc.free(self.scenicScores);
    }

    fn checkTree(self: *@This(), tree: u8, x: usize, y: usize) void {
        const pos = y * self.width + x;
        if (tree > self.highest) {
            self.markers.set(pos);
            self.highest = tree;
        }

        var range: u32 = 0;
        for (self.history[self.historyIndex..], 0..) |h, i| {
            if (h >= tree) {
                range = @intCast(i + 1);
                break;
            }
        }
        if (range == 0) range = @intCast(self.history.len - self.historyIndex);

        self.scenicScores[pos] *= range;
        self.historyIndex -%= 1;
        self.history[self.historyIndex] = tree;
    }

    fn resetDirection(self: *@This()) void {
        self.highest = 0;
        self.historyIndex = self.history.len;
    }

    fn result(self: *const @This()) Result {
        const totalVisible = self.markers.count();

        var highestScore: u32 = 0;
        for (self.scenicScores) |score| {
            if (score > highestScore) highestScore = score;
        }

        return Result{
            .visibleTreeCount = totalVisible,
            .highestScenicScore = highestScore,
        };
    }
};

fn treeCheck(alloc: std.mem.Allocator, input: []const u8) !Result {
    var width: usize = 0;
    while (input[width] != '\n') : (width += 1) {}
    const stride = width + 1;
    const height = input.len / width;

    var state = try State.init(alloc, width, height);
    defer state.deinit();

    {
        var y: usize = 0;
        while (y < height) : (y += 1) {
            state.resetDirection();
            var x: usize = 0;
            while (x < width) : (x += 1) {
                state.checkTree(input[y * stride + x], x, y);
            }

            state.resetDirection();
            x = width - 1;
            while (x < width) : (x -%= 1) {
                state.checkTree(input[y * stride + x], x, y);
            }
        }
    }

    {
        var x: usize = 0;
        while (x < (width - 1)) : (x += 1) {
            state.resetDirection();
            var y: usize = 0;
            while (y < height) : (y += 1) {
                state.checkTree(input[y * stride + x], x, y);
            }

            state.resetDirection();
            y = height - 1;
            while (y < height) : (y -%= 1) {
                state.checkTree(input[y * stride + x], x, y);
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
