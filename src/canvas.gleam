/// Reference to a 2D drawing context on a HTML canvas element
pub type Context

pub type Event {
  Tick(Float)
  MouseMoved(x: Float, y: Float)
  MousePressed(MouseButton, x: Float, y: Float)
  MouseReleased(MouseButton)
}

pub type MouseButton {
  MouseButtonLeft
  MouseButtonRight
  MouseButtonMiddle
}

@external(javascript, "./canvas_ffi.mjs", "register_component")
pub fn register_component(
  name name: String,
  init init: fn() -> model,
  update update: fn(model, Event) -> model,
  // Observed canvas width and height are passed as floats to render.
  // Rendering is done by mutating the canvas context, so nothing is returned.
  render render: fn(model, Context, Float, Float) -> Nil,
  // Attribute handlers are called when the specified attribute changes
  // and can update the model in response
  attribute_handlers attribute_handlers: List(#(String, fn(String) -> model)),
) -> Result(Nil, Nil)

@external(javascript, "./canvas_ffi.mjs", "set_fill_style")
pub fn set_fill_style(ctx: Context, style: String) -> Nil

@external(javascript, "./canvas_ffi.mjs", "set_stroke_style")
pub fn set_stroke_style(ctx: Context, style: String) -> Nil

@external(javascript, "./canvas_ffi.mjs", "set_line_width")
pub fn set_line_width(ctx: Context, width: Float) -> Nil

@external(javascript, "./canvas_ffi.mjs", "set_line_cap")
pub fn set_line_cap(ctx: Context, cap: String) -> Nil

@external(javascript, "./canvas_ffi.mjs", "set_line_join")
pub fn set_line_join(ctx: Context, join: String) -> Nil

@external(javascript, "./canvas_ffi.mjs", "set_font")
pub fn set_font(ctx: Context, font: String) -> Nil

@external(javascript, "./canvas_ffi.mjs", "set_text_align")
pub fn set_text_align(ctx: Context, align: String) -> Nil

@external(javascript, "./canvas_ffi.mjs", "set_global_alpha")
pub fn set_global_alpha(ctx: Context, alpha: Float) -> Nil

@external(javascript, "./canvas_ffi.mjs", "set_global_composite_operation")
pub fn set_global_composite_operation(ctx: Context, operation: String) -> Nil

// Drawing operations
@external(javascript, "./canvas_ffi.mjs", "begin_path")
pub fn begin_path(ctx: Context) -> Nil

@external(javascript, "./canvas_ffi.mjs", "move_to")
pub fn move_to(ctx: Context, x: Float, y: Float) -> Nil

@external(javascript, "./canvas_ffi.mjs", "line_to")
pub fn line_to(ctx: Context, x: Float, y: Float) -> Nil

@external(javascript, "./canvas_ffi.mjs", "stroke")
pub fn stroke(ctx: Context) -> Nil

@external(javascript, "./canvas_ffi.mjs", "ellipse")
pub fn ellipse(
  ctx: Context,
  x: Float,
  y: Float,
  radius_x: Float,
  radius_y: Float,
  rotation: Float,
  start_angle: Float,
  end_angle: Float,
) -> Nil

@external(javascript, "./canvas_ffi.mjs", "fill")
pub fn fill(ctx: Context) -> Nil

@external(javascript, "./canvas_ffi.mjs", "fill_text")
pub fn fill_text(ctx: Context, text: String, x: Float, y: Float) -> Nil

@external(javascript, "./canvas_ffi.mjs", "fill_rect")
pub fn fill_rect(
  ctx: Context,
  x: Float,
  y: Float,
  width: Float,
  height: Float,
) -> Nil

@external(javascript, "./canvas_ffi.mjs", "arc")
pub fn arc(
  ctx: Context,
  x: Float,
  y: Float,
  radius: Float,
  start_angle: Float,
  end_angle: Float,
) -> Nil

@external(javascript, "./canvas_ffi.mjs", "clear_rect")
pub fn clear_rect(
  ctx: Context,
  x: Float,
  y: Float,
  width: Float,
  height: Float,
) -> Nil
