use magnus::{define_module, function};

fn wrapper() -> &'static str {
    "Hello World"
}

#[magnus::init]
fn init() -> Result<(), magnus::Error> {
    let module = define_module("Perb")?;
    module.define_module_function("wrapper", function!(wrapper, 0))?;
    Ok(())
}
