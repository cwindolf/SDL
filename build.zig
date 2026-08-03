const std = @import("std");
const linux = @import("src/linux.zig");
const windows = @import("src/windows.zig");
const macos = @import("src/macos.zig");
const ios = @import("src/ios.zig");
const build_zon = @import("build.zig.zon");
const Translator = @import("translate_c").Translator;

const assert = std.debug.assert;

pub const sources = @import("src/sdl.zon");

pub const flags = &.{
    "-fno-strict-aliasing",
    "-fvisibility=hidden",
    "-DUSING_GENERATED_CONFIG_H",
};

pub fn build(b: *std.Build) !void {
    // Get the upstream source and build options
    const upstream = b.dependency("sdl", .{});
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const default_target_config = b.option(
        bool,
        "default_target_config",
        \\provides a default `SDL_build_config.h` and dependencies for the current target, defaults
        \\to true
        ,
    ) orelse true;

    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        \\whether to build a static or dynamic library, defaults to static
        ,
    ) orelse .static;

    const main_callbacks = b.option(bool, "main_callbacks",
        \\build SDL3_main to enter the app through SDL_AppInit/Iterate/Event/Quit rather
        \\than a classic SDL_main, defaults to false
    ) orelse false;

    const can_san = target.result.os.tag != .ios;

    // Create the library
    const lib = b.addLibrary(.{
        .name = "SDL3",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .sanitize_c = if (can_san) null else .off,
        }),
        .linkage = linkage,
        .version = comptime std.SemanticVersion.parse(build_zon.dependencies.sdl.so_version) catch unreachable,
    });
    switch (linkage) {
        .dynamic => {
            lib.root_module.addCMacro("DLL_EXPORT", "1");
            lib.setVersionScript(upstream.path("src/dynapi/SDL_dynapi.sym"));
        },
        .static => lib.root_module.addCMacro("SDL_STATIC_LIB", "1"),
    }
    lib.root_module.addCMacro("SDL_VENDOR_INFO", std.fmt.comptimePrint("\"{s} {s} (SDL {s})\"", .{
        "https://github.com/allyourcodebase/SDL3",
        build_zon.version,
        build_zon.dependencies.sdl.version,
    }));
    lib.installHeadersDirectory(upstream.path("include/SDL3"), "SDL3", .{});
    b.installArtifact(lib);

    // Set the include path
    lib.root_module.addIncludePath(upstream.path("include"));
    lib.root_module.addIncludePath(upstream.path("src"));
    lib.root_module.addIncludePath(upstream.path("src/video/khronos"));

    // Compile the generic sources
    lib.root_module.addCSourceFiles(.{
        .files = &sources.generic,
        .root = upstream.path("src"),
        .flags = flags,
    });

    const main_lib = b.addLibrary(.{
        .name = "SDL3_main",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .sanitize_c = if (can_san) null else .off,
        }),
        .linkage = .static,
    });
    main_lib.root_module.addIncludePath(upstream.path("include"));
    if (main_callbacks) {
        main_lib.root_module.addCMacro("SDL_MAIN_USE_CALLBACKS", "1");
    }
    main_lib.root_module.addCSourceFile(.{ .file = b.path("src/sdl_main.c") });
    addAppleSdkPathsToModule(b, target.result, main_lib.root_module);
    b.installArtifact(main_lib);

    if (default_target_config) {
        const build_config_h = b.addConfigHeader(.{
            .style = .{ .cmake = upstream.path("include/build_config/SDL_build_config.h.cmake") },
            .include_path = "SDL_build_config.h",
        }, .{
            // Generic audio drivers
            .SDL_AUDIO_DRIVER_DUMMY = true,
            .SDL_AUDIO_DRIVER_DISK = true,

            // Generic video drivers
            .SDL_VIDEO_DRIVER_DUMMY = true,
            .SDL_VIDEO_DRIVER_OFFSCREEN = true,

            // Set the assert level, this logic mirrors the default SDL options with release
            // safe added.
            // https://wiki.libsdl.org/SDL3/SDL_ASSERT_LEVEL
            .SDL_DEFAULT_ASSERT_LEVEL_CONFIGURED = true,
            .SDL_DEFAULT_ASSERT_LEVEL = switch (optimize) {
                .Debug, .ReleaseSafe => @as(i64, 2),
                .ReleaseSmall, .ReleaseFast => @as(i64, 1),
            },
        });
        lib.root_module.addConfigHeader(build_config_h);

        // Configure the build for the target platform
        switch (target.result.os.tag) {
            .linux => linux.build(b, target.result, lib, build_config_h),
            .windows => windows.build(b, target.result, lib, build_config_h),
            .macos => macos.build(b, target.result, lib, build_config_h),
            .ios => ios.build(b, target.result, lib, build_config_h),
            else => @panic("target has no default config"),
        }
    }

    // Add the Wayland scanner step
    linux.addWaylandScannerStep(b);

    // Translate the SDL headers and export them as a Zig module
    const translate_c = b.dependency("translate_c", .{});
    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("src/sdl.h"),
        .target = target,
        // https://codeberg.org/ziglang/translate-c/issues/327
        .optimize = switch (target.result.os.tag) {
            .windows => switch (optimize) {
                .ReleaseSafe => .ReleaseFast,
                else => optimize,
            },
            else => optimize,
        },
    });

    translator.defineCMacro("USING_GENERATED_CONFIG_H", "1");
    translator.addIncludePath(upstream.path("include"));
    translator.addIncludePath(upstream.path("src/video/khronos"));
    translator.mod.linkLibrary(lib);
    try b.modules.putNoClobber(b.graph.arena, "sdl3", translator.mod);
    addAppleSdkPathsToTranslator(b, target.result, translator);
    if (target.result.os.tag == .ios) {
        translator.defineCMacro("TARGET_OS_IPHONE", "1");
    }

    // Add the example
    const example = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    example.root_module.addImport("sdl3", translator.mod);

    const build_example_step = b.step("example", "Build the example app");
    build_example_step.dependOn(&example.step);

    const run_example = b.addRunArtifact(example);
    const run_step = b.step("run-example", "Run the example app");
    run_step.dependOn(&run_example.step);
}

pub fn addAppleSdkPathsToTranslator(b: *std.Build, target: std.Target, translator: Translator) void {
    if (!target.os.tag.isDarwin()) return;

    const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &target) orelse
        @panic("Couldn't detect Apple SDK");

    translator.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "usr/include" }) });
    translator.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "System/Library/Frameworks" }) });
    translator.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "System/Library/SubFrameworks" }) });
    translator.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "usr/lib" }) });
}

pub fn addAppleSdkPathsToModule(b: *std.Build, target: std.Target, module: *std.Build.Module) void {
    if (!target.os.tag.isDarwin()) return;

    const sdk = std.zig.system.darwin.getSdk(b.allocator, b.graph.io, &target) orelse
        @panic("Couldn't detect Apple SDK");

    module.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "usr/include" }) });
    module.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "System/Library/Frameworks" }) });
    module.addSystemFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "System/Library/SubFrameworks" }) });
    module.addLibraryPath(.{ .cwd_relative = b.pathJoin(&.{ sdk, "usr/lib" }) });
}
