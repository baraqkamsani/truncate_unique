const std = @import("std");

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
            .{
                @tagName(target_query.os_tag.?),
                @tagName(target_query.cpu_arch.?),
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

    // Create the Cosmopolitan build step
    const cosmo_step = b.step("cosmo", "Build universal binary with Cosmopolitan");
    const cosmo = b.addSystemCommand(&[_][]const u8{
        "cosmocc",
        "-o",
        "zig-out/bin/cosmo-hello_world.exe",
        "main.c",
    });
    const objcopy = b.addSystemCommand(&[_][]const u8{
        "objcopy",
        "-S",
        "-O",
        "binary",
        "zig-out/bin/cosmo-hello_world.exe",
        "zig-out/bin/cosmo-hello_world.exe",
    });
    objcopy.step.dependOn(&cosmo.step);
    const chmod = b.addSystemCommand(&[_][]const u8{
        "chmod",
        "+x",
        "zig-out/bin/cosmo-hello_world.exe",
    });
    chmod.step.dependOn(&objcopy.step);
    cosmo_step.dependOn(&chmod.step);

    // Also add GCC builds for comparison - placing in zig-out/bin
    const gcc_dynamic = b.addSystemCommand(&[_][]const u8{
        "gcc",
        "-o",
        "zig-out/bin/gcc-hello_world-dynamic",
        "main.c",
    });
    const gcc_static = b.addSystemCommand(&[_][]const u8{
        "gcc",
        "-static",
        "-o",
        "zig-out/bin/gcc-hello_world-static",
        "main.c",
    });
    cosmo_step.dependOn(&gcc_dynamic.step);
    cosmo_step.dependOn(&gcc_static.step);

    // Make "all" include the "cosmo" step as well
    all_step.dependOn(cosmo_step);

    // Make "all" the default step
    b.getInstallStep().dependOn(all_step);
}
