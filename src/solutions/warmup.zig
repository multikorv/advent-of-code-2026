const std = @import("std");
const rl = @import("raylib");

const num_threads: u32 = 8;
const screen_width: u32 = 400;
const screen_height: u32 = 400;

const Vec2Int = struct { x: i32, y: i32 };

pub fn mandelbrotWorker(
    start: Vec2Int,
    end: Vec2Int, 
    zoom: f64, 
    outResult: *[screen_width][screen_height]u32
) void
{
    for (@intCast(start.x)..@intCast(end.x)) |x|
    {
        for (@intCast(start.y)..@intCast(end.y)) |y|
        {
            const x_float: f64 = @floatFromInt(x);
            const y_float: f64 = @floatFromInt(y);
            const width_float: f64 = @floatFromInt(screen_width);
            const height_float: f64 = @floatFromInt(screen_height);
            const x_scaled: f64 = (0.366484 + (x_float / width_float - 0.5) / zoom);
            const y_scaled: f64 = (-0.10006309 + (y_float / height_float - 0.5) / zoom);

            var xx: f64 = 0.0;
            var yy: f64 = 0.0;
            var iteration: u32 = 0;

            var w: f64 = 0.0;
            var x_squared: f64 = 0.0;
            var y_squared: f64 = 0.0;

            while ((xx + yy) <= 4.0 and iteration < 1000)
            {
                xx = x_squared - y_squared + x_scaled;
                yy = w - x_squared - y_squared - y_scaled;
                x_squared = xx*xx;
                y_squared = yy*yy;
                w = (xx + yy) * (xx + yy);
                iteration += 1;
            }

            outResult[x][y] = iteration;
        }
    }
}

pub fn warmup() !void 
{
    rl.initWindow(screen_width, screen_height, "Advent of code 2026 - Visualizer");

    // Close window and OpenGL context
    defer rl.closeWindow(); 

    rl.setTargetFPS(60); 

    var zoom: f64 = 2;
    var result: [screen_width][screen_height]u32 = @splat(@splat(0));

    var threads: [num_threads]std.Thread = undefined;

    while (!rl.windowShouldClose()) 
    {
        //----- Update -----------------------------------------------------------------------------
        for (0..num_threads) |thread_idx|
        {
            // The start index is inclusive, and the end end index is exclusive, 
            // so they do not overlap next iteration
            const start_x: i32 = @intCast(thread_idx * (screen_width / num_threads));
            const end_x: i32 = @intCast((thread_idx + 1) * (screen_width / num_threads));

            const t = try std.Thread.spawn(
                .{}, 
                mandelbrotWorker, 
                .{
                    Vec2Int { .x = start_x, .y = 0 },
                    Vec2Int { .x = end_x, .y = screen_height },
                    zoom,
                    &result
                }
            );

            threads[thread_idx] = t;
        }

        for (threads) |t|
        {
            t.join();
        }

        zoom += 1;

        //----- Draw -------------------------------------------------------------------------------
        rl.clearBackground(.white);
        rl.beginDrawing();

        for(result, 0..) |row, x_idx|
        {
            const x: i32 = @intCast(x_idx);
            for(row, 0..) |num_iterations, y_idx|
            {
                const y: i32 = @intCast(y_idx);
                rl.drawPixel(x, y, getColor(num_iterations));
            }
        }

        defer rl.endDrawing();
        zoom += zoom/30.0;
        //rl.drawText("Advent of code 2026!", 190, 200, 20, .light_gray);
    }
}

pub fn getColor(num_iterations: u64) rl.Color 
{
    if (num_iterations >= 300)
    {
        return .black;
    }
    else if (num_iterations >= 200)
    {
        return .green;
    }
    else if (num_iterations >= 100)
    {
        return .pink;
    }
    else if (num_iterations >= 50)
    {
        return .red;
    }
    else 
    {
        return .yellow;
    }
}
