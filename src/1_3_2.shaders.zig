const std = @import("std");
const builtin = @import("builtin");
const panic = std.debug.panic;
const c = @import("c.zig");

const SCREEN_WIDTH = 1920;
const SCREEN_HEIGHT = 1080;

const vertexShaderSource: [:0]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aColor;
    \\
    \\out vec3 ourColor;
    \\
    \\void main()
    \\{
    \\   gl_Position = vec4(aPos, 1.0);
    \\   ourColor = aColor;
    \\};
;

const fragmentShaderSource: [:0]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\in vec3 ourColor;
    \\
    \\void main()
    \\{
    \\   FragColor = vec4(ourColor, 1.0);
    \\};
;

pub fn main() void {
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

    // vertex shader
    const vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
    const vertexSrcPtr: ?[*]const u8 = vertexShaderSource.ptr;
    c.glShaderSource(vertexShader, 1, &vertexSrcPtr, null);
    c.glCompileShader(vertexShader);
    // check for shader compile errors
    var success: c_int = undefined;
    var infoLog: [512]u8 = undefined;
    c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(vertexShader, 512, null, &infoLog);
        panic("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }

    // fragment shader
    const fragmentShader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    const fragmentSrcPtr: ?[*]const u8 = fragmentShaderSource.ptr;
    c.glShaderSource(fragmentShader, 1, &fragmentSrcPtr, null);
    c.glCompileShader(fragmentShader);
    // check for shader compile errors
    c.glGetShaderiv(fragmentShader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(vertexShader, 512, null, &infoLog);
        panic("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }

    // link shaders
    const shaderProgram = c.glCreateProgram();
    c.glAttachShader(shaderProgram, vertexShader);
    c.glAttachShader(shaderProgram, fragmentShader);
    c.glLinkProgram(shaderProgram);
    // check for linking errors
    c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(vertexShader, 512, null, &infoLog);
        panic("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog});
    }
    c.glDeleteShader(vertexShader);
    c.glDeleteShader(fragmentShader);
    defer c.glDeleteProgram(shaderProgram);

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
        // const time_value = c.glfwGetTime();
        // const green_value = @floatCast(f32, std.math.sin((time_value) / 2.0) + 0.5);
        // const vertex_color_location = c.glGetUniformLocation(shaderProgram, "ourColor");
        // c.glUniform4f(vertex_color_location, 0.0, green_value, 0.0, 0.0);
        c.glUseProgram(shaderProgram);
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
