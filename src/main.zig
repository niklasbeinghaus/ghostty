const std = @import("std");
const glfw = @import("glfw");
const gl = @import("opengl.zig");
const stb = @import("stb.zig");

pub fn main() !void {
    try glfw.init(.{});
    defer glfw.terminate();

    // Load our image
    var imgwidth: c_int = 0;
    var imgheight: c_int = 0;
    var imgchannels: c_int = 0;
    const data = stb.c.stbi_load_from_memory(
        texsrc,
        texsrc.len,
        &imgwidth,
        &imgheight,
        &imgchannels,
        0,
    );
    if (data == null) return error.TexFail;
    stb.c.stbi_image_free(data);

    // Create our window
    const window = try glfw.Window.create(640, 480, "ghostty", null, null, .{
        .context_version_major = 3,
        .context_version_minor = 3,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
    });
    defer window.destroy();

    // Setup OpenGL
    try glfw.makeContextCurrent(window);
    try glfw.swapInterval(1);
    window.setSizeCallback((struct {
        fn callback(_: glfw.Window, width: i32, height: i32) void {
            std.log.info("set viewport {} {}", .{ width, height });
            gl.c.glViewport(0, 0, width, height);
        }
    }).callback);

    // Create our vertex shader
    const vs = try gl.Shader.create(gl.c.GL_VERTEX_SHADER);
    try vs.setSourceAndCompile(vs_source);
    defer vs.destroy();

    const fs = try gl.Shader.create(gl.c.GL_FRAGMENT_SHADER);
    try fs.setSourceAndCompile(fs_source);
    defer fs.destroy();

    // Shader program
    const program = try gl.Program.create();
    defer program.destroy();
    try program.attachShader(vs);
    try program.attachShader(fs);
    try program.link();
    vs.destroy();
    fs.destroy();

    // Create our bufer or vertices
    const vertices = [_]f32{
        -0.5, -0.5, 0.0, // left
        0.5, -0.5, 0.0, // right
        0.0, 0.5, 0.0, // top
    };
    const vao = try gl.VertexArray.create();
    defer vao.destroy();
    const vbo = try gl.Buffer.create();
    defer vbo.destroy();
    try vao.bind();
    var binding = try vbo.bind(gl.c.GL_ARRAY_BUFFER);
    try binding.setData(&vertices, gl.c.GL_STATIC_DRAW);
    try binding.vertexAttribPointer(0, 3, gl.c.GL_FLOAT, false, 3 * @sizeOf(f32), null);
    try binding.enableVertexAttribArray(0);

    binding.unbind();
    try gl.VertexArray.unbind();

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        // Setup basic OpenGL settings
        gl.c.glClearColor(0.2, 0.3, 0.3, 1.0);
        gl.c.glClear(gl.c.GL_COLOR_BUFFER_BIT);

        try program.use();
        try program.setUniform("vertexColor", @Vector(4, f32){ 0.0, 1.0, 0.0, 1.0 });

        try vao.bind();
        gl.c.glDrawArrays(gl.c.GL_TRIANGLES, 0, 3);

        // const pos = try window.getCursorPos();
        // std.log.info("CURSOR: {}", .{pos});

        try window.swapBuffers();
        try glfw.waitEvents();
    }
}

const texsrc = @embedFile("tex.png");

const vs_source =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\
    \\void main()
    \\{
    \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;

const fs_source =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\uniform vec4 vertexColor;
    \\
    \\void main()
    \\{
    \\    FragColor = vertexColor;
    \\}
;
