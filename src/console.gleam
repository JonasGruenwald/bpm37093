
@external(javascript, "./console_ffi.mjs", "log")
pub fn log(payload: a) -> Nil

@external(javascript, "./console_ffi.mjs", "log")
pub fn log_3(payload_1: a, payload_2: b, payload_3: c) -> Nil

@external(javascript, "./console_ffi.mjs", "error")
pub fn error(payload: a) -> Nil

@external(javascript, "./console_ffi.mjs", "info")
pub fn info(payload: a) -> Nil

@external(javascript, "./console_ffi.mjs", "warn")
pub fn warn(payload: a) -> Nil

@external(javascript, "./console_ffi.mjs", "debug")
pub fn debug(payload: a) -> Nil