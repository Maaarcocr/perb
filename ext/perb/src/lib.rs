use std::mem;

use magnus::{define_module, function, rb_sys::FromRawValue};
use dynasmrt::{dynasm, DynasmApi};

fn wrapper() -> magnus::Value {
    let mut ops = dynasmrt::x64::Assembler::new().unwrap();
    let asm_wrapper = ops.offset();
    dynasm!(ops
        ; xor rcx, rcx
        ; mov rax, QWORD rb_sys::rb_yield as _
        ; call rax
        ; ret
    );
    let buf = ops.finalize().unwrap();

    let asm_wrapper_fn: extern "win64" fn() -> rb_sys::Value =
        unsafe { mem::transmute(buf.ptr(asm_wrapper)) };

    unsafe {
        magnus::Value::from_raw(asm_wrapper_fn())
    }
}

#[magnus::init]
fn init() -> Result<(), magnus::Error> {
    let module = define_module("Perb")?;
    module.define_module_function("wrapper", function!(wrapper, 0))?;
    Ok(())
}
