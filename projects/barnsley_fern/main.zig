const std = @import("std");
const cat = @import("cat");
const rl = cat.raylib;

var x: f32 = 0;
var y: f32 = 0;

pub fn main() !void {
    try init(
        900,
        650,
        "first",
        // allocator,
        rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_MAXIMIZED,
        60,
        // 23,
    );
    defer deinit();

    while (!rl.WindowShouldClose()) {
        {
            {
                // Update
            }

            {
                // Events
                if (rl.IsWindowResized()) {
                    rl.ClearBackground(rl.GetColor(0x404040FF));
                }
                if (rl.IsKeyPressed(rl.KEY_F)) toggle_fullscreen(rl.GetRenderWidth(), rl.GetRenderHeight());
            }
            {
                // Draw
                rl.BeginDrawing();
                defer rl.EndDrawing();

                for (0..100) |_| {
                    drawPoint();
                    nextPoint();
                }
            }
        }
    }
}

//Config-------------------------------------------------------------------------------
fn init(
    width: i32,
    height: i32,
    name: [*c]const u8,
    // allocator: std.mem.Allocator,
    config_flags: ?rl.ConfigFlags,
    fps: ?i32,
    // imgui_font_size: f32,
) !void {
    var w: f32 = @floatFromInt(width);
    var h: f32 = @floatFromInt(height);

    const scale: f32 = 1.6;

    w *= scale;
    h *= scale;

    if (config_flags) |_config_flags| rl.SetConfigFlags(_config_flags);
    rl.InitWindow(@intFromFloat(w), @intFromFloat(h), name);
    if (fps) |_fps| rl.SetTargetFPS(_fps);

    rl.ClearBackground(rl.GetColor(0x404040FF));
}

fn deinit() void {
    rl.CloseWindow();
}

fn draw_fps(allocator: std.mem.Allocator, fontrl: rl.Font, postition: rl.Vector2, font_size: f32) !void {
    const fps = rl.GetFPS();
    const fps_text = try std.fmt.allocPrintZ(allocator, "FPS: {d}", .{fps});
    defer allocator.free(fps_text);
    rl.DrawTextEx(
        fontrl,
        fps_text,
        postition,
        font_size,
        1,
        if (fps < 60) rl.RED else rl.GREEN,
    );
}

fn toggle_fullscreen(width: c_int, height: c_int) void {
    if (!rl.IsWindowFullscreen()) {
        rl.ToggleFullscreen();
        const monitor = rl.GetCurrentMonitor();
        rl.SetWindowSize(rl.GetMonitorWidth(monitor), rl.GetMonitorHeight(monitor));
    } else {
        rl.ToggleFullscreen();
        rl.SetWindowSize(width, height);
    }
}
//--------------------------------------------------------------------

fn nextPoint() void {
    var nextX: f32 = undefined;
    var nextY: f32 = undefined;
    const r = rl.GetRandomValue(0, 100);

    if (r < 10) {
        nextY = 0.16 * y;
        nextX = 0;
    } else if (r < 86) {
        nextX = 0.85 * x + 0.04 * y;
        nextY = -0.04 * x + 0.85 * y + 1.6;
    } else if (r < 93) {
        nextX = 0.2 * x + -0.26 * y;
        nextY = 0.23 * x + 0.22 * y + 1.6;
    } else {
        nextX = -0.15 * x + 0.28 * y;
        nextY = 0.26 * x + 0.24 * y + 0.44;
    }
    x = nextX;
    y = nextY;
}

fn drawPoint() void {
    const px = map(x, -2.182, 2.6558, 0, @floatFromInt(rl.GetScreenWidth()));
    const py = map(y, 0, 9.9983, @floatFromInt(rl.GetScreenHeight()), 0);

    rl.DrawCircleV(.{ .x = px, .y = py }, 3, rl.GREEN);
}

fn map(in: f32, in_min: f32, in_max: f32, out_min: f32, out_max: f32) f32 {
    return (in - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
