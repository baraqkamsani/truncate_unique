const std = @import("std");
const exe_name = "hello_world";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const targets = [_]std.Target.Query{
        .{ .os_tag = .windows, .cpu_arch = .x86_64 },
        .{ .os_tag = .windows, .cpu_arch = .aarch64 },
        .{ .os_tag = .linux, .cpu_arch = .x86_64 },
        .{ .os_tag = .linux, .cpu_arch = .aarch64 },
        .{ .os_tag = .macos, .cpu_arch = .x86_64 },
        .{ .os_tag = .macos, .cpu_arch = .aarch64 },
    };

    // Create a "all" step that will build all targets
    const all_step = b.step("all", "Build for all platforms");

    // Create executable for each target
    for (targets) |target_query| {
        // Format a descriptive name for this target
        var target_name_buffer: [64]u8 = undefined;
        const target_name = std.fmt.bufPrintZ(
            &target_name_buffer,
            "{s}-{s}",
            .{ @tagName(target_query.os_tag.?), @tagName(target_query.cpu_arch.?) },
        ) catch "unknown";

        // Create the executable with target-specific name
        const exe = b.addExecutable(.{
            .name = b.fmt("{s}-zig-{s}", .{ exe_name, target_name }),
            .root_source_file = b.path("main.zig"),
            .target = b.resolveTargetQuery(target_query),
            .optimize = optimize,
        });

        const install_exe = b.addInstallArtifact(exe, .{});
        all_step.dependOn(&install_exe.step);
    }

    b.getInstallStep().dependOn(all_step);
}
