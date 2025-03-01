const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard optimization options
    const optimize = b.standardOptimizeOption(.{});

    // Define targets to build for
    const targets = [_]std.Target.Query{
        // Windows (x86_64 and ARM64)
        .{ .os_tag = .windows, .cpu_arch = .x86_64 },
        .{ .os_tag = .windows, .cpu_arch = .aarch64 },
        // Linux (x86_64 and ARM64)
        .{ .os_tag = .linux, .cpu_arch = .x86_64 },
        .{ .os_tag = .linux, .cpu_arch = .aarch64 },
        // macOS (x86_64 and ARM64)
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
            .{
                @tagName(target_query.cpu_arch.?),
                @tagName(target_query.os_tag.?),
            },
        ) catch "unknown";

        // Create the executable with target-specific name
        const exe = b.addExecutable(.{
            .name = b.fmt("hello_world-{s}", .{target_name}),
            .root_source_file = b.path("main.zig"),
            .target = b.resolveTargetQuery(target_query),
            .optimize = optimize,
        });

        // Install artifact
        const install_exe = b.addInstallArtifact(exe, .{});

        // Make the "all" step depend on building this target
        all_step.dependOn(&install_exe.step);
    }

    // Make "all" the default step
    b.getInstallStep().dependOn(all_step);
}
