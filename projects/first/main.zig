const std = @import("std");
const cat = @import("cat");
const rl = cat.raylib;
const c = cat.rlimgui;
const imgui = cat.imgui;
const plot = imgui.plot;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        std.debug.print("{}\n", .{leaked});
    }
    const allocator = gpa.allocator();

    try init(
        900,
        650,
        "first",
        allocator,
        rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_MAXIMIZED,
        60,
        23,
    );
    defer deinit();

    const fontrl = rl.LoadFont("fonts/Roboto-Medium.ttf");
    defer rl.UnloadFont(fontrl);
    rl.SetTextureFilter(fontrl.texture, rl.TEXTURE_FILTER_BILINEAR);

    while (!rl.WindowShouldClose()) {
        {
            {
                // Update
            }

            {
                // Events

            }
            {
                // Draw
                rl.BeginDrawing();
                defer rl.EndDrawing();
                rl.ClearBackground(rl.GetColor(0x404040FF));

                try draw_fps(
                    allocator,
                    fontrl,
                    .{ .x = 12, .y = 12 },
                    50,
                );
                {
                    // Draw ImGui
                    c.rlImGuiBegin();
                    defer c.rlImGuiEnd();
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
    allocator: std.mem.Allocator,
    config_flags: ?rl.ConfigFlags,
    fps: ?i32,
    imgui_font_size: f32,
) !void {
    var w: f32 = @floatFromInt(width);
    var h: f32 = @floatFromInt(height);

    const scale: f32 = 1.6;

    w *= scale;
    h *= scale;

    if (config_flags) |_config_flags| rl.SetConfigFlags(_config_flags);
    rl.InitWindow(@intFromFloat(w), @intFromFloat(h), name);
    if (fps) |_fps| rl.SetTargetFPS(_fps);

    c.rlImGuiSetup(true);
    imgui.initNoContext(allocator);

    const font = imgui.io.addFontFromFile("fonts/Roboto-Medium.ttf", imgui_font_size * scale);
    imgui.io.setDefaultFont(font);
    c.rlImGuiReloadFonts();
    imgui.io.setIniFilename("first.ini");
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

fn imgui_plot() void {
    // const fps: u32 = @intCast(rl.GetFPS());
    // const fps_text = try std.fmt.allocPrintZ(allocator, "{d}", .{fps});
    // defer allocator.free(fps_text);

    // const frames = try allocator.alloc(u32, 100);
    // defer allocator.free(frames);

    // for (frames) |*value| {
    //     value.* = fps;
    // }

    // imgui.setNextWindowPos(.{ .x = 0, .y = 0 });
    // imgui.setNextWindowSize(.{ .w = 500, .h = 500 });
    if (imgui.begin("Debug", .{ .flags = .{ .no_title_bar = true, .no_scrollbar = true } })) {
        const static = struct {
            const size = 500;
            const t = f32;
            var xvalues: [size]t = .{0} ** size;
            var yvalues: [size]t = .{0} ** size;
        };

        for (0..static.xvalues.len) |i| {
            const fi: f32 = @floatFromInt(i);
            static.xvalues[i] = fi * 0.001;
            const time: f32 = @floatCast(rl.GetTime());
            static.yvalues[i] = 0.5 + 0.5 * @sin(50 * (static.xvalues[i] + time / 10));
        }

        plot.init();
        if (plot.beginPlot(
            "f(x)",
            .{ .h = 400 },
        )) {
            // const static = struct {
            //     var count: f32 = 0;
            // };
            // static.count += rl.GetFrameTime();
            // plot.setupAxisLimits(.x1, .{
            //     .min = 0,
            //     .max = @floatCast(static.count),
            // });
            // plot.setupAxisLimits(.y1, .{
            //     .min = -1,
            //     .max = 1,
            // });
            plot.setupAxis(.x1, .{});
            plot.setupAxis(.y1, .{});

            plot.plotLine("FPS", static.t, .{
                .xv = &static.xvalues,
                .yv = &static.yvalues,
                .flags = .{},
            });
        }
        plot.endPlot();
    }
    imgui.end();
}
//--------------------------------------------------------------------
