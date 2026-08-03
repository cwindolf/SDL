const std = @import("std");
const build_zon = @import("../build.zig.zon");
const sources = @import("sdl.zon");
const root = @import("../build.zig");
const Subsystems = root.Subsystems;
const AllDrivers = root.Drivers;

pub fn build(
    b: *std.Build,
    target: std.Target,
    lib: *std.Build.Step.Compile,
    build_config_h: *std.Build.Step.ConfigHeader,
) void {
    const upstream = b.dependency("sdl", .{});
    // _ = target;
    lib.root_module.addIncludePath(b.dependency("egl", .{}).path("api"));
    lib.root_module.addIncludePath(b.dependency("opengl", .{}).path("api"));

    root.addAppleSdkPathsToModule(b, target, lib.root_module);

    // Link with the platform specific system frameworks
    lib.root_module.linkFramework("UIKit", .{});
    lib.root_module.linkFramework("CoreMotion", .{});
    lib.root_module.linkFramework("CoreVideo", .{});
    lib.root_module.linkFramework("CoreAudio", .{});
    lib.root_module.linkFramework("CoreHaptics", .{});
    lib.root_module.linkFramework("CoreFoundation", .{});
    lib.root_module.linkFramework("CoreMedia", .{});
    lib.root_module.linkFramework("CoreGraphics", .{});
    lib.root_module.linkFramework("Metal", .{});
    lib.root_module.linkFramework("QuartzCore", .{});
    lib.root_module.linkFramework("AudioToolbox", .{});
    lib.root_module.linkFramework("AVFoundation", .{});
    lib.root_module.linkFramework("Foundation", .{});
    lib.root_module.linkFramework("GameController", .{});
    lib.root_module.linkFramework("CoreBluetooth", .{});
    lib.root_module.linkFramework("UniformTypeIdentifiers", .{});
    lib.root_module.linkFramework("OpenGLES", .{});
    // lib.root_module.linkSystemLibrary("iconv", .{});

    // Add the platform specific sources
    const objc_flags = root.flags.* ++ [_][]const u8{"-fobjc-arc"};
    lib.root_module.addCSourceFiles(.{
        .files = &(sources.uikit ++ sources.darwin ++ sources.ios ++ sources.unix ++ sources.pthread),
        .root = upstream.path("src"),
        .flags = &objc_flags,
    });

    // Set the platform specific build config
    build_config_h.addValues(.{
        .HAVE_GCC_ATOMICS = 1,

        .HAVE_ALLOCA_H = 1,
        .HAVE_FLOAT_H = 1,
        .HAVE_INTTYPES_H = 1,
        .HAVE_LIMITS_H = 1,
        .HAVE_MATH_H = 1,
        .HAVE_SIGNAL_H = 1,
        .HAVE_STDARG_H = 1,
        .HAVE_STDDEF_H = 1,
        .HAVE_STDINT_H = 1,
        .HAVE_STDIO_H = 1,
        .HAVE_STDLIB_H = 1,
        .HAVE_STRING_H = 1,
        .HAVE_SYS_TYPES_H = 1,
        .HAVE_WCHAR_H = 1,

        // C library functions
        .HAVE_LIBC = 1,
        .HAVE_DLOPEN = 1,
        .HAVE_MALLOC = 1,
        .HAVE_GETENV = 1,
        .HAVE_GETHOSTNAME = 1,
        .HAVE_PUTENV = 1,
        .HAVE_SETENV = 1,
        .HAVE_UNSETENV = 1,
        .HAVE_ABS = 1,
        .HAVE_BCOPY = 1,
        .HAVE_MEMSET = 1,
        .HAVE_MEMCPY = 1,
        .HAVE_MEMMOVE = 1,
        .HAVE_MEMCMP = 1,
        .HAVE_STRLEN = 1,
        .HAVE_STRLCPY = 1,
        .HAVE_STRLCAT = 1,
        .HAVE_STRCHR = 1,
        .HAVE_STRRCHR = 1,
        .HAVE_STRSTR = 1,
        .HAVE_STRTOK_R = 1,
        .HAVE_STRTOL = 1,
        .HAVE_STRTOUL = 1,
        .HAVE_STRTOLL = 1,
        .HAVE_STRTOULL = 1,
        .HAVE_STRTOD = 1,
        .HAVE_ATOI = 1,
        .HAVE_ATOF = 1,
        .HAVE_STRCMP = 1,
        .HAVE_STRNCMP = 1,
        .HAVE_STRPBRK = 1,
        .HAVE_VSSCANF = 1,
        .HAVE_VSNPRINTF = 1,
        .HAVE_ACOS = 1,
        .HAVE_ACOSF = 1,
        .HAVE_ASIN = 1,
        .HAVE_ASINF = 1,
        .HAVE_ATAN = 1,
        .HAVE_ATANF = 1,
        .HAVE_ATAN2 = 1,
        .HAVE_ATAN2F = 1,
        .HAVE_CEIL = 1,
        .HAVE_CEILF = 1,
        .HAVE_COPYSIGN = 1,
        .HAVE_COPYSIGNF = 1,
        .HAVE_COS = 1,
        .HAVE_COSF = 1,
        .HAVE_EXP = 1,
        .HAVE_EXPF = 1,
        .HAVE_FABS = 1,
        .HAVE_FABSF = 1,
        .HAVE_FLOOR = 1,
        .HAVE_FLOORF = 1,
        .HAVE_FMOD = 1,
        .HAVE_FMODF = 1,
        .HAVE_ISINF = 1,
        .HAVE_ISINF_FLOAT_MACRO = 1,
        .HAVE_ISNAN = 1,
        .HAVE_ISNAN_FLOAT_MACRO = 1,
        .HAVE_LOG = 1,
        .HAVE_LOGF = 1,
        .HAVE_LOG10 = 1,
        .HAVE_LOG10F = 1,
        .HAVE_LROUND = 1,
        .HAVE_LROUNDF = 1,
        .HAVE_MODF = 1,
        .HAVE_MODFF = 1,
        .HAVE_POW = 1,
        .HAVE_POWF = 1,
        .HAVE_ROUND = 1,
        .HAVE_ROUNDF = 1,
        .HAVE_SCALBN = 1,
        .HAVE_SCALBNF = 1,
        .HAVE_SIN = 1,
        .HAVE_SINF = 1,
        .HAVE_SQRT = 1,
        .HAVE_SQRTF = 1,
        .HAVE_TAN = 1,
        .HAVE_TANF = 1,
        .HAVE_TRUNC = 1,
        .HAVE_TRUNCF = 1,
        .HAVE_SIGACTION = 1,
        .HAVE_SETJMP = 1,
        .HAVE_NANOSLEEP = 1,
        .HAVE_GMTIME_R = 1,
        .HAVE_LOCALTIME_R = 1,
        .HAVE_NL_LANGINFO = 1,
        .HAVE_SYSCONF = 1,
        .HAVE_SYSCTLBYNAME = 1,
        .HAVE_O_CLOEXEC = 1,

        // enable iPhone version of Core Audio driver
        .SDL_AUDIO_DRIVER_COREAUDIO = 1,
        // Enable the dummy audio driver (src/audio/dummy/\*.c)
        .SDL_AUDIO_DRIVER_DUMMY = 1,

        // Enable the stub haptic driver (src/haptic/dummy/\*.c)
        .SDL_HAPTIC_DUMMY = 1,

        // Enable joystick support
        // Only enable HIDAPI support if you want to support Steam Controllers on iOS and tvOS
        .SDL_JOYSTICK_MFI = 1,
        .SDL_JOYSTICK_VIRTUAL = 1,

        // Enable various process implementations
        .SDL_PROCESS_DUMMY = 1,

        // Enable the CoreMotion sensor driver
        .SDL_SENSOR_COREMOTION = 1,

        // Enable Unix style SO loading
        .SDL_LOADSO_DLOPEN = 1,

        // Enable various threading systems
        .SDL_THREAD_PTHREAD = 1,
        .SDL_THREAD_PTHREAD_RECURSIVE_MUTEX = 1,

        // Enable various RTC system
        .SDL_TIME_UNIX = 1,

        // Enable various timer systems
        .SDL_TIMER_UNIX = 1,

        // Supported video drivers
        .SDL_VIDEO_DRIVER_UIKIT = 1,
        .SDL_VIDEO_DRIVER_DUMMY = 1,

        // .SDL_PLATFORM_SUPPORTS_METAL = 1,
        .SDL_VIDEO_OPENGL_ES2 = 1,
        .SDL_VIDEO_OPENGL_ES = 1,
        .SDL_VIDEO_RENDER_OGL_ES2 = 1,

        .SDL_VIDEO_METAL = 1,
        .SDL_VIDEO_VULKAN = 1,
        .SDL_GPU_METAL = 1,
        .SDL_GPU_VULKAN = 1,
        .SDL_VIDEO_RENDER_METAL = 1,
        .SDL_VIDEO_RENDER_GPU = 1,

        // Enable system power support
        .SDL_POWER_UIKIT = 1,

        // enable iPhone keyboard support
        .SDL_IPHONE_KEYBOARD = 1,

        // enable iOS extended launch screen
        .SDL_IPHONE_LAUNCHSCREEN = 1,

        // enable filesystem support
        .SDL_FILESYSTEM_COCOA = 1,
        .SDL_FSOPS_POSIX = 1,

        .SDL_CAMERA_DRIVER_DUMMY = 1,

        // Enable dialog subsystem
        .SDL_DIALOG_DUMMY = 1,

        // Enable tray subsystem
        .SDL_TRAY_DUMMY = 1,

        // Disable ARM SVE2 intrinsics until we confirm they're available on all Apple mobile and TV hardware
        // .SDL_DISABLE_SVE2 = 1,

        // Enable steam storage
        .SDL_STORAGE_STEAM = 1,

        // Unused
        .SDL_AUDIO_DRIVER_ALSA_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_JACK_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_PIPEWIRE_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_PULSEAUDIO_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_SNDIO_DYNAMIC = "",
        .SDL_LIBUSB_DYNAMIC = "",
        .SDL_UDEV_DYNAMIC = "",
        .SDL_VIDEO_DRIVER_KMSDRM_DYNAMIC = "",
        .SDL_VIDEO_DRIVER_KMSDRM_DYNAMIC_GBM = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_CURSOR = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_EGL = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_LIBDECOR = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_XKBCOMMON = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XCURSOR = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XEXT = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XFIXES = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XINPUT2 = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XRANDR = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XSS = "",
        .SDL_CAMERA_DRIVER_PIPEWIRE_DYNAMIC = "",
        .SDL_LIBDECOR_VERSION_MAJOR = "",
        .SDL_LIBDECOR_VERSION_MINOR = "",
        .SDL_LIBDECOR_VERSION_PATCH = "",
        .SDL_FRIBIDI_DYNAMIC = "",
        .SDL_LIBTHAI_DYNAMIC = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XTEST = "",
        .SDL_VIDEO_DRIVER_X11_XINPUT2_SUPPORTS_GESTURE = "",
        .SDL_XKBCOMMON_VERSION_MAJOR = "",
        .SDL_XKBCOMMON_VERSION_MINOR = "",
        .SDL_XKBCOMMON_VERSION_PATCH = "",
        .SDL_EMSCRIPTEN_PERSISTENT_PATH_STRING = "",
    });
}
