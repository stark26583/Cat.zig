const std = @import("std");
const cat = @import("cat");
const rl = cat.raylib;
const c = cat.rlimgui;
const imgui = cat.imgui;
const plot = imgui.plot;
const cp = cat.cp;
// const CB = @import("circle_bounce.zig");

var world: cp.World = undefined;
// var circle_bounce: CB = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        std.debug.print("{}\n", .{leaked});
    }
    const allocator = gpa.allocator();

    try init(
        1900,
        950,
        "first",
        allocator,
        null,
        60,
        23,
    );
    defer deinit();

    // const w: f32 = @floatFromInt(rl.GetScreenWidth());
    // const h: f32 = @floatFromInt(rl.GetScreenHeight());

    // circle_bounce = CB.init(allocator, &world);

    // const n_segments = 32;
    // const circle = CB.Circle{ .x = w / 2, .y = h / 2, .radius = h / 3 };
    // const segments = try circle_bounce.add_circle_segment(circle, n_segments);
    // allocator.free(segments.segments);

    const fontrl = rl.LoadFont("fonts/Roboto-Medium.ttf");
    defer rl.UnloadFont(fontrl);
    rl.SetTextureFilter(fontrl.texture, rl.TEXTURE_FILTER_BILINEAR);

    var gravity: f32 = 600;

    while (!rl.WindowShouldClose()) {
        {
            {
                // Update
                world.update(rl.GetFrameTime());
                cp.c.cpSpaceSetGravity(world.space, .{ .x = 0.0, .y = gravity });
            }

            {
                // Events
                if (rl.IsKeyPressed(rl.KEY_SPACE)) {
                    const pos = rl.Vector2{
                        .x = @floatFromInt(rl.GetRandomValue(10, rl.GetScreenWidth())),
                        .y = @floatFromInt(rl.GetRandomValue(10, rl.GetScreenHeight())),
                    };
                    // const velocity = rl.Vector2{
                    //     .x = @floatFromInt(rl.GetRandomValue(-800, 900)),
                    //     .y = @floatFromInt(rl.GetRandomValue(-900, 800)),
                    // };
                    const angular_velocity: f32 = @floatFromInt(rl.GetRandomValue(-100, 100));
                    const radius: f32 = @floatFromInt(rl.GetRandomValue(10, 50));
                    _ = try world.addObject(
                        .{
                            .body = .{
                                .dynamic = .{
                                    .position = .{ .x = pos.x, .y = pos.y },
                                    // .velocity = .{ .x = velocity.x, .y = velocity.y },
                                    .angular_velocity = angular_velocity,
                                },
                            },
                            .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
                                cp.World.ObjectOption.ShapeProperty{ .circle = .{ .radius = radius, .physics = .{
                                    .elasticity = 0.9,
                                    .weight = .{ .mass = radius * 0.4 },
                                } } },
                            },
                        },
                    );
                    _ = try world.addObject(
                        .{
                            .body = .{
                                .dynamic = .{
                                    .position = .{ .x = pos.x + radius * 3 + 10, .y = pos.y },
                                    // .velocity = .{ .x = velocity.x, .y = velocity.y },
                                    .angular_velocity = angular_velocity,
                                },
                            },
                            .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
                                cp.World.ObjectOption.ShapeProperty{ .circle = .{ .radius = radius * 2, .physics = .{
                                    .elasticity = 0.9,
                                    .weight = .{ .mass = radius * 0.4 * 2 },
                                } } },
                            },
                        },
                    );
                }

                // if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                //     const pos = rl.GetMousePosition();
                //     if (rl.CheckCollisionPointCircle(pos, .{ .x = circle.x, .y = circle.y }, circle.radius)) {
                //         _ = try world.addObject(
                //             .{
                //                 .body = .{
                //                     .dynamic = .{
                //                         .position = .{ .x = pos.x, .y = pos.y },
                //                     },
                //                 },
                //                 .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
                //                     .{
                //                         .circle = .{
                //                             .radius = 40,
                //                             .physics = .{
                //                                 .elasticity = 0,
                //                                 // .friction = 0,
                //                             },
                //                         },
                //                     },
                //                 },
                //             },
                //         );
                //     }
                // }
            }
            {
                // Draw
                rl.BeginDrawing();
                defer rl.EndDrawing();
                rl.ClearBackground(rl.GetColor(0x404040FF));

                // rl.DrawCircleSector(.{ .x = circle.x, .y = circle.y }, circle.radius, 0, 360, n_segments, rl.BLACK);

                for (1..world.objects.items.len) |c_| {
                    draw_cp_circle(c_, rl.YELLOW);
                }

                try draw_fps(
                    allocator,
                    fontrl,
                    .{ .x = 12, .y = 12 },
                    70,
                );

                const text = try std.fmt.allocPrintZ(allocator, "No. of Objects: {d}", .{world.objects.items.len});
                defer allocator.free(text);
                rl.DrawTextEx(
                    fontrl,
                    text,
                    .{ .x = 12, .y = 100 },
                    60,
                    1,
                    rl.WHITE,
                );

                {
                    // Draw ImGui
                    c.rlImGuiBegin();
                    defer c.rlImGuiEnd();

                    if (imgui.begin("Controls", .{})) {
                        _ = imgui.sliderFloat("gravity", .{ .v = &gravity, .cfmt = "%.0f", .min = 0, .max = 2000 });
                    }
                    imgui.end();
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
    const w: f32 = @floatFromInt(width);
    const h: f32 = @floatFromInt(height);

    if (config_flags) |_config_flags| rl.SetConfigFlags(_config_flags);
    rl.InitWindow(@intFromFloat(w), @intFromFloat(h), name);
    if (fps) |_fps| rl.SetTargetFPS(_fps);

    c.rlImGuiSetup(true);
    imgui.initNoContext(allocator);

    const font = imgui.io.addFontFromFile("fonts/Roboto-Medium.ttf", imgui_font_size);
    imgui.io.setDefaultFont(font);
    c.rlImGuiReloadFonts();
    imgui.io.setIniFilename(null);

    world = try cp.World.init(allocator, .{ .gravity = .{ .x = 0.0, .y = 600 } });

    _ = try bounding_box(.{ .x = 0, .y = 0, .w = w, .h = h }, 1, 0.5);
}

fn deinit() void {
    world.deinit();
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

// fn get_delta_time() f32 {

// }
//--------------------------------------------------------------------

fn draw_cp_circle(
    circle: usize,
    color: rl.Color,
) void {
    const radius = cp.c.cpCircleShapeGetRadius(world.objects.items[circle].shapes[0]);
    const pos = cp.c.cpBodyGetPosition(world.objects.items[circle].body);
    const posi = cp.c.cpCircleShapeGetOffset(world.objects.items[circle].shapes[0]);
    const position = rl.Vector2{ .x = pos.x + posi.x, .y = pos.y + posi.y };

    const angle = cp.c.cpBodyGetAngle(world.objects.items[circle].body);

    rl.DrawCircleV(position, radius, color);
    rl.DrawLineEx(
        position,
        rl.Vector2{ .x = position.x + @cos(angle) * radius, .y = position.y + @sin(angle) * radius },
        radius * 0.2,
        rl.BLACK,
    );
}

pub fn bounding_box(rect: struct { x: f32, y: f32, w: f32, h: f32 }, elasticity: f32, friction: f32) !u32 {
    return world.addObject(.{
        .body = .global_static,
        .shapes = &.{
            cp.World.ObjectOption.ShapeProperty{
                .segment = .{
                    .a = .{ .x = rect.x, .y = rect.y + rect.h },
                    .b = .{ .x = rect.x + rect.w, .y = rect.y + rect.h },
                    .radius = 10,
                    .physics = .{ .elasticity = elasticity, .friction = friction },
                },
            },
            cp.World.ObjectOption.ShapeProperty{
                .segment = .{
                    .a = .{ .x = rect.x, .y = rect.y },
                    .b = .{ .x = rect.x, .y = rect.y + rect.h },
                    .radius = 10,
                    .physics = .{ .elasticity = elasticity, .friction = friction },
                },
            },
            cp.World.ObjectOption.ShapeProperty{
                .segment = .{
                    .a = .{ .x = rect.x + rect.w, .y = rect.y },
                    .b = .{ .x = rect.x + rect.w, .y = rect.y + rect.h },
                    .radius = 10,
                    .physics = .{ .elasticity = elasticity, .friction = friction },
                },
            },
            cp.World.ObjectOption.ShapeProperty{
                .segment = .{
                    .a = .{ .x = rect.x, .y = rect.y },
                    .b = .{ .x = rect.x + rect.w, .y = rect.y },
                    .radius = 10,
                    .physics = .{ .elasticity = elasticity, .friction = friction },
                },
            },
        },
    });
}

// fn debug_draw() void {
//     if(rl.IsKeyPressed(rl.KEY_Q)){
//     for (world.objects.items) |object| {

//         for (object.shapes) |shape| {
//             if(cp.c.cpShapePointQuery())
//         }
//     }
//     }
// }
