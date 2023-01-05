use std::{io::Write, mem};

use dynasmrt::{dynasm, AssemblyOffset, DynasmApi};
use magnus::{define_module, function, rb_sys::FromRawValue};

fn build_wrapper(fn_name: String) -> usize {
    let mut ops = dynasmrt::x64::Assembler::new().unwrap();
    let asm_wrapper = ops.offset();

    dynasm!(ops
        ; push rbp
        ; mov rbp, rsp
        ; xor rdi, rdi
        ; mov rax, QWORD rb_sys::rb_yield as _
        ; call rax
        ; leave
        ; ret
    );

    let end_offset = AssemblyOffset(ops.offset().0 - 1);

    ops.commit().unwrap();

    let buf = ops.finalize().unwrap();

    let file_name = format!("/tmp/perf-{}.map", std::process::id());
    let file = std::fs::OpenOptions::new()
        .append(true)
        .create(true)
        .open(file_name)
        .unwrap();
    let fn_ptr = buf.ptr(asm_wrapper) as usize;
    let mut line_writer = std::io::LineWriter::new(file);
    let len = unsafe { buf.ptr(end_offset).offset_from(buf.ptr(asm_wrapper)) };
    let perf_map = format!(
        "{:x} {:x} {}\n",
        fn_ptr,
        len,
        fn_name
    );
    line_writer.write_all(perf_map.as_bytes()).unwrap();
    Box::leak(Box::new(buf));
    fn_ptr
}

fn wrapper(fn_pointer: usize) -> magnus::Value {
    unsafe {
        let asm_wrapper_fn: extern "C" fn() -> rb_sys::Value = mem::transmute(fn_pointer);
        magnus::Value::from_raw(asm_wrapper_fn())
    }
}

#[magnus::init]
fn init() -> Result<(), magnus::Error> {
    let module = define_module("Perb")?;
    module.define_module_function("wrapper", function!(wrapper, 1))?;
    module.define_module_function("build_wrapper", function!(build_wrapper, 1))?;
    Ok(())
}
