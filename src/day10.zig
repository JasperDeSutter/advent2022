const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("10", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;
    const result = try interestingSignalStrengths(input);

    var imageOutput: [41 * 6]u8 = undefined;
    result.render(&imageOutput);
    std.debug.print("imageOutput:\n{s}", .{imageOutput});

    return .{
        result.interestingSignalStrengths,
        0,
    };
}

const Result = struct {
    interestingSignalStrengths: u32,
    litPixels: std.StaticBitSet(40 * 6),

    fn render(self: *const @This(), buf: *[41 * 6]u8) void {
        var y: usize = 0;
        while (y < 6) : (y += 1) {
            var x: usize = 0;
            var row = buf[y * 41 ..];
            while (x < 40) : (x += 1) {
                const lit = self.litPixels.isSet(y * 40 + x);
                if (lit) {
                    row[x] = '#';
                } else {
                    row[x] = '.';
                }
            }
            row[40] = '\n';
        }
    }
};

fn render(display: *std.StaticBitSet(240), cycle: u32, spriteIndex: i32) void {
    const rowIndex: i32 = @intCast(cycle % 40);
    if (@abs(rowIndex - spriteIndex) < 2) {
        display.set(cycle);
    }
}

fn interestingSignalStrengths(input: []const u8) !Result {
    var lines = std.mem.split(u8, input, "\n");

    var cycle: u32 = 0;
    var result: u32 = 0;
    var registerX: i32 = 1;
    var display = std.StaticBitSet(240).initEmpty();
    render(&display, cycle, registerX);

    while (lines.next()) |line| {
        var increment: i32 = 0;
        var interval: u32 = 0;
        if (std.mem.eql(u8, line, "noop")) {
            interval = 1;
        } else {
            interval = 2;
            increment = try std.fmt.parseInt(i32, line[5..], 10);
        }

        if (interval == 2) {
            render(&display, cycle + 1, registerX);
        }

        cycle += interval;
        const check = (cycle + 20) % 40;
        if (check < interval) {
            var value = registerX;
            if (interval == 0) value += increment;
            result += (cycle - check) * @as(u32, @intCast(value));
        }
        registerX += increment;

        render(&display, cycle, registerX);
    }

    return Result{
        .interestingSignalStrengths = result,
        .litPixels = display,
    };
}

test {
    const input =
        \\addx 15
        \\addx -11
        \\addx 6
        \\addx -3
        \\addx 5
        \\addx -1
        \\addx -8
        \\addx 13
        \\addx 4
        \\noop
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx -35
        \\addx 1
        \\addx 24
        \\addx -19
        \\addx 1
        \\addx 16
        \\addx -11
        \\noop
        \\noop
        \\addx 21
        \\addx -15
        \\noop
        \\noop
        \\addx -3
        \\addx 9
        \\addx 1
        \\addx -3
        \\addx 8
        \\addx 1
        \\addx 5
        \\noop
        \\noop
        \\noop
        \\noop
        \\noop
        \\addx -36
        \\noop
        \\addx 1
        \\addx 7
        \\noop
        \\noop
        \\noop
        \\addx 2
        \\addx 6
        \\noop
        \\noop
        \\noop
        \\noop
        \\noop
        \\addx 1
        \\noop
        \\noop
        \\addx 7
        \\addx 1
        \\noop
        \\addx -13
        \\addx 13
        \\addx 7
        \\noop
        \\addx 1
        \\addx -33
        \\noop
        \\noop
        \\noop
        \\addx 2
        \\noop
        \\noop
        \\noop
        \\addx 8
        \\noop
        \\addx -1
        \\addx 2
        \\addx 1
        \\noop
        \\addx 17
        \\addx -9
        \\addx 1
        \\addx 1
        \\addx -3
        \\addx 11
        \\noop
        \\noop
        \\addx 1
        \\noop
        \\addx 1
        \\noop
        \\noop
        \\addx -13
        \\addx -19
        \\addx 1
        \\addx 3
        \\addx 26
        \\addx -30
        \\addx 12
        \\addx -1
        \\addx 3
        \\addx 1
        \\noop
        \\noop
        \\noop
        \\addx -9
        \\addx 18
        \\addx 1
        \\addx 2
        \\noop
        \\noop
        \\addx 9
        \\noop
        \\noop
        \\noop
        \\addx -1
        \\addx 2
        \\addx -37
        \\addx 1
        \\addx 3
        \\noop
        \\addx 15
        \\addx -21
        \\addx 22
        \\addx -6
        \\addx 1
        \\noop
        \\addx 2
        \\addx 1
        \\noop
        \\addx -10
        \\noop
        \\noop
        \\addx 20
        \\addx 1
        \\addx 2
        \\addx 2
        \\addx -6
        \\addx -11
        \\noop
        \\noop
        \\noop
    ;

    const image =
        \\##..##..##..##..##..##..##..##..##..##..
        \\###...###...###...###...###...###...###.
        \\####....####....####....####....####....
        \\#####.....#####.....#####.....#####.....
        \\######......######......######......####
        \\#######.......#######.......#######.....
        \\
    ;

    const result = try interestingSignalStrengths(input);
    try std.testing.expectEqual(result.interestingSignalStrengths, 13140);

    var imageOutput: [41 * 6]u8 = undefined;
    result.render(&imageOutput);
    try std.testing.expectEqualSlices(u8, image, &imageOutput);
}
