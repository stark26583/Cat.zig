const std = @import("std");
const cat = @import("cat");
const rl = cat.raylib;
const c = cat.rlimgui;
const imgui = cat.imgui;

pub fn main() !void {
    const screen_width = 1400;
    const screen_height = 900;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        std.debug.print("{}\n", .{leaked});
    }
    const allocator = gpa.allocator();

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
    rl.InitWindow(screen_width, screen_height, "second");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    c.rlImGuiSetup(true);
    defer c.rlImGuiShutdown();
    imgui.initNoContext(allocator);
    defer imgui.deinitNoContext();
    const font = imgui.io.addFontFromFile("fonts/Roboto-Medium.ttf", 25);
    imgui.io.setDefaultFont(font);
    c.rlImGuiReloadFonts();
    imgui.io.setIniFilename("second.ini");

    const fontrl = rl.LoadFont("fonts/Roboto-Medium.ttf");
    defer rl.UnloadFont(fontrl);

    rl.SetTextureFilter(fontrl.texture, rl.TEXTURE_FILTER_BILINEAR);

    var camera = rl.Camera3D{
        .position = .{ .x = 0, .y = 5, .z = 10 },
        .target = .{ .x = 0, .y = 0, .z = 0 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = rl.CAMERA_PERSPECTIVE,
    };

    const cubePosition = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
    // const cubeScreenPosition = rl.Vector2{ .x = 0.0, .y = 0.0 };

    // Main loop
    while (!rl.WindowShouldClose()) {
        // Game updates
        rl.UpdateCamera(&camera, rl.CAMERA_THIRD_PERSON);

        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) rl.DisableCursor();
        // if (rl.IsKeyPressed(rl.KEY_F)) toggle_fullscreen(rl.GetRenderWidth(), rl.GetRenderHeight());
        // Draw Raylib
        {
            rl.BeginDrawing();
            defer rl.EndDrawing();
            rl.ClearBackground(rl.GetColor(0x404040FF));

            rl.BeginMode3D(camera);

            rl.DrawCube(cubePosition, 20, 2, 2, rl.RED);
            rl.DrawCubeWires(cubePosition, 2, 2, 2, rl.MAROON);

            rl.DrawGrid(10, 1.0);

            rl.EndMode3D();

            const text = try std.fmt.allocPrintZ(allocator, "FPS: {d}", .{rl.GetFPS()});
            defer allocator.free(text);

            rl.DrawTextEx(fontrl, text, .{ .x = 12, .y = 12 }, 50, 1, rl.GREEN);

            // Draw ImGui
            {
                c.rlImGuiBegin();
                defer c.rlImGuiEnd();
            }
        }
    }
}

fn toRaylibColor(col: [4]f32) rl.Color {
    return .{
        .r = @intFromFloat(col[0] * 255),
        .g = @intFromFloat(col[1] * 255),
        .b = @intFromFloat(col[2] * 255),
        .a = @intFromFloat(col[3] * 255),
    };
}
