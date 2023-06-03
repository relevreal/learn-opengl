const std = @import("std");
const builtin = @import("builtin");
const panic = std.debug.panic;
const join = std.fs.path.join;
const c = @import("c.zig");

const Shader = @import("shader.zig").Shader;

const SCREEN_WIDTH = 1920;
const SCREEN_HEIGHT = 1080;

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    const vertPath = try join(allocator, &[_][]const u8{ "..", "shaders", "1_3_shaders.vert" });
    const fragPath = try join(allocator, &[_][]const u8{ "..", "shaders", "1_3_shaders.frag" });

    const ok = c.glfwInit();
    if (ok == 0) {
        panic("failed to initialize GLFW\n", .{});
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);

    // glfw: initialize and configure
    var window = c.glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Learn OpenGL", null, null);
    if (window == null) {
        panic("Failed to create GLFW window\n", .{});
    }

    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // glad: load all OpenGL function pointers
    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress)) == 0) {
        panic("Failed to initialise GLAD\n", .{});
    }

    // build and compile our shader program
    const ourShader = try Shader.init(allocator, vertPath, fragPath);

    // set up vertex data (and buffer(s)) and configure vertex attributes
    const vertices = [_]f32{
        // positions     // colors
        0.5,  -0.5, 0.0, 1.0, 0.0, 0.0,
        -0.5, -0.5, 0.0, 0.0, 1.0, 0.0,
        0.0,  0.5,  0.0, 0.0, 0.0, 1.0,
    };

    var VAO: c_uint = undefined;
    var VBO: c_uint = undefined;
    c.glGenVertexArrays(1, &VAO);
    c.glGenBuffers(1, &VBO);
    defer c.glDeleteVertexArrays(1, &VAO);
    defer c.glDeleteBuffers(1, &VBO);

    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    // position attribute
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);
    // color attribute
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @intToPtr(*const f32, 3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    // debug: checking if data got copied
    // var data: [12]f32 = undefined;
    // c.glGetBufferSubData(c.GL_ARRAY_BUFFER, 0, vertices.len * @sizeOf(f32), @ptrCast(*anyopaque, &data));

    c.glBindVertexArray(0);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    // c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
    // render loop
    while (c.glfwWindowShouldClose(window) == 0) {
        // input
        processInput(window);

        // render
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // draw our first triangle
        ourShader.use();
        c.glBindVertexArray(VAO); // seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}

// glfw: whenever the window size changed (by OS or user resize) this callback function executes
pub fn framebuffer_size_callback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    // make sure the viewport matches the new window dimensions; note that width and
    // height will be significantly larger than specified on retina displays.
    c.glViewport(0, 0, width, height);
}

// process all input: query GLFW whether relevant keys are pressed/released this frame and react accordingly
pub fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS)
        c.glfwSetWindowShouldClose(window, 1);
}
