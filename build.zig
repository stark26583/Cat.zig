const std = @import("std");
const zgui = @import("zgui");
const cp = @import("src/deps/chipmunk/build.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

    const assets_install = b.addInstallDirectory(.{
        .source_dir = .{ .path = "fonts" },
        .install_dir = .bin,
        .install_subdir = "fonts",
    });

    const Project = struct {
        name: []const u8,
        use_cp: bool = false,
    };
    const projects = [_]Project{
        .{ .name = "first" },
        .{ .name = "second" },
        .{ .name = "fractal_tree" },
        .{ .name = "physics_sandbox", .use_cp = true },
        .{ .name = "barnsley_fern" },
    };

    inline for (projects) |project| {
        const exe = try create_executable(
            b,
            project.name,
            "projects/" ++ project.name ++ "/main.zig",
            target,
            optimize,
            project.use_cp,
        );
        b.installArtifact(exe);

        const install_cmd = b.addInstallArtifact(exe, .{});
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&install_cmd.step);
        run_cmd.step.dependOn(&assets_install.step);

        run_cmd.cwd = std.Build.LazyPath{ .path = "zig-out/bin" };
        const run_step = b.step(
            project.name,
            "run project " ++ project.name,
        );
        run_step.dependOn(&run_cmd.step);
    }
}

pub fn create_executable(
    b: *std.Build,
    name: []const u8,
    root_file: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    use_cp: bool,
) !*std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .cwd_relative = root_file },
        .target = target,
        .optimize = optimize,
    });

    b.verbose_air = true;

    exe.addIncludePath(.{ .cwd_relative = "src/deps/raylib/include" });
    exe.addLibraryPath(.{ .cwd_relative = "src/deps/raylib/lib" });

    if (exe.rootModuleTarget().os.tag == .windows) {
        exe.linkLibC();
        exe.linkSystemLibrary("raylib");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("winmm");
    } else if (exe.rootModuleTarget().os.tag == .linux) {
        exe.linkSystemLibrary("raylib");
        exe.linkSystemLibrary("m");
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("X11");
    }

    exe.linkLibCpp();
    const zgui_pkg = zgui.package(b, target, optimize, .{
        .options = .{ .backend = .no_backend },
    });
    zgui_pkg.link(exe);

    const rlimgui_cflags = &.{
        "-fno-sanitize=undefined",
        "-std=c++11",
        "-Wno-deprecated-declarations",
        "-DNO_FONT_AWESOME",
    };

    const rlimgui = b.dependency("rlimgui", .{
        .target = target,
        .optimize = optimize,
    });

    const cat = b.createModule(.{ .root_source_file = .{ .cwd_relative = "src/cat.zig" }, .target = target, .optimize = optimize, .imports = &.{
        .{ .name = "zgui", .module = getZguiModule(b, target, optimize) },
    } });
    cat.addIncludePath(.{ .cwd_relative = "src/deps/raylib/include" });
    cat.addCSourceFile(.{
        .file = rlimgui.path("rlImGui.cpp"),
        .flags = rlimgui_cflags,
    });
    cat.addIncludePath(rlimgui.path("."));
    cat.addIncludePath(.{ .cwd_relative = "src/deps/zgui/libs/imgui" });

    const cp_module = b.createModule(.{
            .root_source_file = .{ .cwd_relative = "src/deps/chipmunk/chipmunk.zig" },
            .target = target,
            .optimize = optimize,
        });
    cat.addImport("cp", cp_module);
    cat.addIncludePath(.{ .cwd_relative = "src/deps/chipmunk/c/include/" });

    if (use_cp) {
        cp.link(exe);
    }
    exe.root_module.addImport("cat", cat);

    return exe;
}

pub fn getZguiModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
) *std.Build.Module {
    const pkg = zgui.package(b, target, optimize, .{
        .options = .{ .backend = .no_backend },
    });
    return pkg.zgui;
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
