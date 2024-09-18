const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("17", solve);

const OpenMap = std.ArrayListUnmanaged(bool);

const width: usize = 8;

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var map = try std.ArrayListUnmanaged(u8).initCapacity(alloc, width * 3);
    defer map.deinit(alloc);
    map.expandToCapacity();
    initLines(map.items);

    var inputIdx: usize = 0;

    for (0..2022) |i| {
        const shape = i % 5;
        const rows: usize = switch (shape) {
            0 => 1,
            1 => 3,
            2 => 3,
            3 => 4,
            4 => 2,
            else => unreachable,
        };

        var new = try map.addManyAsSlice(alloc, rows * width);
        initLines(new);

        switch (shape) {
            0 => @memset(new[2..][0..4], '@'),
            1 => {
                new[3] = '@';
                @memset(new[width + 2 ..][0..3], '@');
                new[2 * width + 3] = '@';
            },
            2 => {
                @memset(new[2..][0..3], '@');
                new[width + 4] = '@';
                new[2 * width + 4] = '@';
            },
            3 => {
                new[2] = '@';
                new[width + 2] = '@';
                new[2 * width + 2] = '@';
                new[3 * width + 2] = '@';
            },
            4 => {
                new[2] = '@';
                new[3] = '@';
                new[width + 2] = '@';
                new[width + 3] = '@';
            },
            else => unreachable,
        }

        var operatingSlice = new;

        outer: while (true) {
            if (input[inputIdx] == '>') {
                for (operatingSlice, 0..) |b, j| {
                    if (b != '@') continue;
                    const right = operatingSlice[j + 1];
                    if (right != '.' and right != '@') {
                        break;
                    }
                } else { // can move
                    var j = operatingSlice.len;
                    while (j > 1) : (j -= 1) {
                        if (operatingSlice[j - 2] == '@') {
                            operatingSlice[j - 1] = '@';
                            operatingSlice[j - 2] = '.';
                        }
                    }
                }
            } else {
                for (operatingSlice, 0..) |b, j| {
                    if (b != '@') continue;
                    if (j == 0) break;

                    const left = operatingSlice[j - 1];
                    if (left != '.' and left != '@') {
                        break;
                    }
                } else { // can move
                    for (operatingSlice, 0..) |*b, j| {
                        if (b.* == '@') {
                            operatingSlice[j - 1] = '@';
                            b.* = '.';
                        }
                    }
                }
            }

            if (operatingSlice.ptr == map.items.ptr) {
                break;
            }

            operatingSlice.ptr -= width; // including one more row
            operatingSlice.len += width;
            for (operatingSlice, 0..) |b, j| {
                if (b != '@') continue;
                const under = operatingSlice[j - width];
                if (under != '.' and under != '@') {
                    break :outer;
                }
            } else { // can move
                for (operatingSlice, 0..) |*b, j| {
                    if (b.* == '@') {
                        operatingSlice[j - width] = '@';
                        b.* = '.';
                    }
                }
            }

            operatingSlice.len -= width;
            inputIdx = (inputIdx + 1) % input.len;
        }
        inputIdx = (inputIdx + 1) % input.len;

        for (operatingSlice) |*b| {
            if (b.* == '@') {
                b.* = '#';
            }
        }

        {
            var j: usize = map.items.len - 1;
            while (j > 0) : (j -= 1) {
                if (map.items[j] == '#') {
                    break;
                }
            }
            map.items.len = j - @rem(j, width) + 4 * width;
        }
    }

    return .{ map.items.len / width - 3, 0 };
}

fn printMap(lines: []const u8) void {
    var j = lines.len / width;
    std.debug.print(" \n\n", .{});
    while (j > 0) : (j -= 1) {
        std.debug.print("|{s}\n", .{lines[(j - 1) * width ..][0..width]});
    }
    std.debug.print("+-------+\n", .{});
}

fn initLines(lines: []u8) void {
    for (0..(lines.len / width)) |i| {
        const line = lines[i * width ..];
        @memset(line[0 .. width - 1], '.');
        line[width - 1] = '|';
    }
}

fn parseValve(txt: []const u8) u16 {
    var b: u16 = @intCast(txt[1] - 'A');
    b *= 26;
    return b + @as(u16, @intCast(txt[0] - 'A'));
}

test {
    const input =
        \\>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>
    ;
    const results = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(3068, results[0]);
    // try std.testing.expectEqual(1_514_285_714_288, results[1]);
}
