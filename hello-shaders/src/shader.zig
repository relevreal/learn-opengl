const std = @import("std");
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;
const cwd = std.fs.cwd;
const OpenFlags = std.fs.File.OpenFlags;
const OpenMode = std.fs.File.OpenMode;
const c = @import("c.zig");
const print = std.debug.print;

pub const Shader = struct {
    id: c_uint,

    pub fn init(allocator: Allocator, vertexPath: []const u8, fragmentPath: []const u8) !Shader {
        // 1. retrieve the vertex/fragment source code from filePath
        const vShaderFile = try cwd().openFile(vertexPath, OpenFlags{ .mode = OpenMode.read_only });
        defer vShaderFile.close();

        const fShaderFile = try cwd().openFile(fragmentPath, OpenFlags{ .mode = OpenMode.read_only });
        defer fShaderFile.close();

        var vertexCode = try allocator.alloc(u8, try vShaderFile.getEndPos());
        defer allocator.free(vertexCode);

        var fragmentCode = try allocator.alloc(u8, try fShaderFile.getEndPos());
        defer allocator.free(fragmentCode);

        _ = try vShaderFile.read(vertexCode);
        _ = try fShaderFile.read(fragmentCode);

        // 2. compile shaders
        // vertex shader
        const vertex = c.glCreateShader(c.GL_VERTEX_SHADER);
        const vertexSrcPtr: ?[*]const u8 = vertexCode.ptr;
        c.glShaderSource(vertex, 1, &vertexSrcPtr, null);
        c.glCompileShader(vertex);
        checkCompileErrors(vertex, "VERTEX");

        // fragment Shader
        const fragment = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        const fragmentSrcPtr: ?[*]const u8 = fragmentCode.ptr;
        c.glShaderSource(fragment, 1, &fragmentSrcPtr, null);
        c.glCompileShader(fragment);
        checkCompileErrors(fragment, "FRAGMENT");

        // shader Program
        const id = c.glCreateProgram();
        c.glAttachShader(id, vertex);
        c.glAttachShader(id, fragment);
        c.glLinkProgram(id);
        checkCompileErrors(id, "PROGRAM");

        // delete the shaders as they're linked into our program now and no longer necessary
        c.glDeleteShader(vertex);
        c.glDeleteShader(fragment);

        return Shader{ .id = id };
    }

    pub fn use(self: Shader) void {
        c.glUseProgram(self.id);
    }

    pub fn setBool(self: Shader, name: [:0]const u8, val: bool) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, name), if (val) 1 else 0);
    }

    pub fn setInt(self: Shader, name: [:0]const u8, val: c_int) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, name), val);
    }

    pub fn setFloat(self: Shader, name: [:0]const u8, val: f32) void {
        c.glUniform1f(c.glGetUniformLocation(self.id, name), val);
    }

    fn checkCompileErrors(shader: c_uint, errType: []const u8) void {
        var success: c_int = undefined;
        var infoLog: [1024]u8 = undefined;
        if (!std.mem.eql(u8, errType, "PROGRAM")) {
            c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
            if (success == 0) {
                c.glGetShaderInfoLog(shader, 1024, null, &infoLog);
                panic("ERROR::SHADER::{s}::COMPILATION_FAILED\n{s}\n", .{ errType, infoLog });
            }
        } else {
            c.glGetShaderiv(shader, c.GL_LINK_STATUS, &success);
            if (success == 0) {
                c.glGetShaderInfoLog(shader, 1024, null, &infoLog);
                panic("ERROR::SHADER::LINKING_FAILED\n{s}\n", .{infoLog});
            }
        }
    }
};