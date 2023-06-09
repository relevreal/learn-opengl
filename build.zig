const std = @import("std");
const currentTarget = @import("builtin").target;
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "hello-triangle",
        .root_source_file = .{ .path = "src/1_3_1_shaders.zig" },
        .target = target,
        .optimize = optimize,
    });

    // includes
    exe.addIncludePath("/usr/local/include");
    exe.addIncludePath("deps/include");

    // sources
    exe.addCSourceFile("deps/src/glad.c", &[_][]const u8{"-std=c99"});
    exe.addCSourceFile("deps/src/stb_image_impl.c", &[_][]const u8{"-std=c99"});

    switch (currentTarget.os.tag) {
        .linux => {
            exe.addLibraryPath("/usr/lib/x86_64-linux-gnu");
            exe.linkSystemLibrary("c");
            exe.linkSystemLibrary("gl");
        },
        else => {
            @panic("don't know how to build on your system");
        },
    }
    exe.linkSystemLibrary("glfw3");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}