const std = @import("std");
const builtin = std.builtin;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    const test_all_step = b.step("test", "Run all tests");
    const run_all_step = b.step("all", "Run all");

    var day: u32 = 1;
    const end: u32 = 17;
    while (day <= end) : (day += 1) {
        if (day == 12) continue;
        var dayStringBuf: [5]u8 = undefined;
        const dayString = try std.fmt.bufPrint(dayStringBuf[0..], "day{:0>2}", .{day});

        const srcFile = b.fmt("src/{s}.zig", .{dayString});

        const exe = b.addExecutable(.{ .name = dayString, .root_source_file = b.path(srcFile), .target = target, .single_threaded = true, .optimize = mode });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        const input_path = b.pathFromRoot(b.fmt("inputdata/{s}.txt", .{dayString}));
        // exe.addAnonymousModule(b.fmt("inputdata/{s}.txt", .{dayString}), .{ .source_file = .{ .path = input_path } });
        run_cmd.addArg(input_path);
        run_all_step.dependOn(&run_cmd.step);

        const build_test_cmd = b.addTest(.{ .root_source_file = b.path(srcFile), .target = target, .single_threaded = true, .optimize = mode });
        const test_cmd = b.addRunArtifact(build_test_cmd);
        test_all_step.dependOn(&test_cmd.step);

        const run_step = b.step(dayString, b.fmt("Run {s}", .{dayString}));
        run_step.dependOn(&run_cmd.step);
        const test_step = b.step(b.fmt("{s}-t", .{dayString}), b.fmt("Test {s}", .{dayString}));
        test_step.dependOn(&test_cmd.step);
        const build_step = b.step(b.fmt("{s}-b", .{dayString}), b.fmt("Build {s}", .{dayString}));
        build_step.dependOn(&exe.step);
    }
}
