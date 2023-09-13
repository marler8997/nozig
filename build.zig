const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) !void {
    // TODO: check zig version is what we expect
    const expected_version = "0.11.0";
    if (!std.mem.eql(u8, builtin.zig_version_string, expected_version)) {
        std.log.info("zig at version '{s}', will re-run with version '{s}'", .{builtin.zig_version_string, expected_version});
        getZigAndRebuild(b);
    }

    std.log.info("TODO: build something normal that only our version of zig supports?", .{});
    //const target = b.standardTargetOptions(.{});
    //const optimize = b.standardOptimizeOption(.{});
}

fn getBuildArgs(self: *std.Build) ![]const [:0]const u8 {
    const args = try std.process.argsAlloc(self.allocator);
    return args[5..];
}

fn getZigAndRebuild(b: *std.Build) noreturn {
    const zig = blk: {
        switch (builtin.os.tag) {
            .linux => {
                std.log.warn("TODO: check if we are on x86_64", .{});
                break :blk b.dependency("zig_linux_x86_64", .{});
            },
            else => {
                std.log.err("unsupported os '{s}'", .{builtin.os.tag});
                return error.UnsupportedOS;
            },
        }
    };
    const exe_ext = if (builtin.os.tag == .windows) ".exe" else "";
    const zig_exe = b.pathJoin(&.{zig.builder.build_root.path.?, "zig" ++ exe_ext});
    std.log.info("zig exe is '{s}'", .{zig_exe});

    const run_step = std.build.RunStep.create(b, "zig build with expected version");
    run_step.addArg(zig_exe);
    run_step.addArg("build");
    run_step.addArg("--build-file");
    run_step.addFileSourceArg(.{ .path = "build.zig" });
    run_step.addArg("--cache-dir");
    const cache_root_path = b.cache_root.path orelse @panic("todo");
    run_step.addArg(b.pathFromRoot(cache_root_path));

    b.default_step = &run_step.step;

    var progress = std.Progress{};
    {
        var prog_node = progress.start("rerun build with expected version", 1);
        run_step.step.make(prog_node) catch |err| switch (err) {
            error.MakeFailed => std.os.exit(0xff), // error already printed by subprocess, hopefully?
            error.MakeSkipped => @panic("impossible?"),
        };
        prog_node.end();
    }
    std.os.exit(0);    
}
