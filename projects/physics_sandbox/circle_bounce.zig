const std = @import("std");
const cp = @import("cp");

const Self = @This();
pub const Circle = struct { x: f32, y: f32, radius: f32 };

world: *cp.World,
allocator: std.mem.Allocator,

/// Initialize the plugin
pub fn init(allocator: std.mem.Allocator, world: *cp.World) Self {
    return Self{
        .world = world,
        .allocator = allocator,
    };
}

pub fn add_circle_segment(self: *Self, circle: Circle, n_segments: usize) !struct { index: u32, segments: []cp.World.ObjectOption.ShapeProperty } {
    const n_segmentsf: f32 = @floatFromInt(n_segments);

    const body = cp.World.ObjectOption.BodyProperty{
        .static = .{ .position = .{ .x = circle.x, .y = circle.y } },
    };
    var segments = try self.allocator.alloc(cp.World.ObjectOption.ShapeProperty, n_segments);

    const step = (2 * std.math.pi) / n_segmentsf;
    var i: usize = 0;
    while (i < n_segments) : (i += 1) {
        const fi: f32 = @floatFromInt(i);
        const angle = fi * step;
        segments[i] = .{
            .segment = .{
                .a = .{ .x = @cos(angle) * circle.radius, .y = @sin(angle) * circle.radius },
                .b = .{ .x = @cos(angle + step) * circle.radius, .y = @sin(angle + step) * circle.radius },
                .radius = 5,
                .physics = .{
                    .elasticity = 0,
                    .friction = 0,
                },
            },
        };
    }

    return .{
        .index = try self.world.addObject(.{ .body = body, .shapes = segments }),
        .segments = segments,
    };
}

pub fn bounding_box(self: *Self, rect: struct { x: f32, y: f32, w: f32, h: f32 }, elasticity: f32, friction: f32) !u32 {
    return self.world.addObject(.{
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

/// Deinitialize the plugin
pub fn deinit(self: Self) !void {
    _ = self; // autofix

    // TODO
}
