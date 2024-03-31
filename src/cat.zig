pub const rlimgui = @cImport({
    @cDefine("NO_FONT_AWESOME", "1");
    @cInclude("rlImGui.h");
});

pub const raylib = @cImport({
    @cInclude("raylib.h");
});
pub const raymath = @cImport(@cInclude("raymath.h"));
pub const imgui = @import("zgui");

pub const cp = @import("cp");
