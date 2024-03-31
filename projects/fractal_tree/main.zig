const std = @import("std");
const c = @cImport({
    @cDefine("NO_FONT_AWESOME", "1");
    @cInclude("rlImGui.h");
});
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const imgui = @import("zgui");

var length_step: f32 = 0.67;
var thickness_step: f32 = 0.67;
var anglestep: f32 = std.math.pi / 4.0;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        std.debug.print("{}\n", .{leaked});
    }
    const allocator = gpa.allocator();

    //static variables
    var lengthv: f32 = 200;
    var thicknessv: f32 = 15;

    init(
        1000,
        700,
        "fractal_tree",
        allocator,
        rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT,
        60,
    );
    defer deinit();

    while (!rl.WindowShouldClose()) {
        const size = vector2(
            @floatFromInt(rl.GetRenderWidth()),
            @floatFromInt(rl.GetRenderHeight()),
        );

        {
            rl.BeginDrawing();
            defer rl.EndDrawing();
            rl.ClearBackground(rl.GetColor(0x404040FF));
            //Draw Raylib

            branch(vector2(size.x / 2, size.y), lengthv, 0, thicknessv);
            {
                c.rlImGuiBegin();
                defer c.rlImGuiEnd();
                // Draw ImGui
                if (imgui.begin("Controller", .{})) {
                    _ = imgui.sliderFloat("length", .{ .min = 50, .max = size.y / 2, .v = &lengthv });
                    _ = imgui.sliderFloat("thickness", .{ .min = 1, .max = 50, .v = &thicknessv });
                    _ = imgui.sliderAngle("angle_step", .{ .vrad = &anglestep, .deg_min = 0, .deg_max = 180 });
                    _ = imgui.sliderFloat("thickness_step", .{ .min = 0, .max = 0.8, .v = &thickness_step });
                    _ = imgui.sliderFloat("length_step", .{ .min = 0, .max = 0.7, .v = &length_step });
                }
                imgui.end();
            }
            rl.DrawFPS(12, 12);
        }
    }
}

fn branch(pos: rl.Vector2, length: f32, angle: f32, thickness: f32) void {
    const nextpos = vector2(pos.x + @sin(angle) * length, pos.y - @cos(angle) * length);

    rl.DrawLineEx(
        pos,
        nextpos,
        thickness,
        rl.RAYWHITE,
    );

    if (length > 5) {
        branch(nextpos, length * length_step, anglestep + angle, thickness * thickness_step);
        branch(nextpos, length * length_step, angle - anglestep, thickness * thickness_step);
    }
}

//Config-------------------------------------------------------------------------------
fn init(
    width: i32,
    height: i32,
    name: [*c]const u8,
    allocator: std.mem.Allocator,
    config_flags: rl.ConfigFlags,
    fps: ?i32,
) void {
    rl.SetConfigFlags(config_flags);
    rl.InitWindow(width, height, name);
    if (fps) |_fps| rl.SetTargetFPS(_fps);

    c.rlImGuiSetup(true);
    imgui.initNoContext(allocator);

    const font = imgui.io.addFontFromFile(
        "fonts/Roboto-Medium.ttf",
        20,
    );
    imgui.io.setDefaultFont(font);
    c.rlImGuiReloadFonts();
    imgui.io.setIniFilename(null);
}

fn deinit() void {
    imgui.deinitNoContext();
    c.rlImGuiShutdown();
    rl.CloseWindow();
}

fn toRaylibColor(col: [4]f32) rl.Color {
    return .{
        .r = @intFromFloat(col[0] * 255),
        .g = @intFromFloat(col[1] * 255),
        .b = @intFromFloat(col[2] * 255),
        .a = @intFromFloat(col[3] * 255),
    };
}

fn vector2(x: f32, y: f32) rl.Vector2 {
    return .{ .x = x, .y = y };
}
//-------------------------------------------------------------------------------------
