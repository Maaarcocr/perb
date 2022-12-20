use magnus::{define_module, function};

fn wrapper() -> magnus::Value {
    unsafe{
    rb_sys::rb_yield(0)
    }
}

#[magnus::init]
fn init() -> Result<(), magnus::Error> {
    let module = define_module("Perb")?;
    module.define_module_function("wrapper", function!(wrapper, 0))?;
    Ok(())
}
