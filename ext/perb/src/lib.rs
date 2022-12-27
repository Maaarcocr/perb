use std::{mem, io::Write, sync::RwLock};

use magnus::{define_module, function, rb_sys::FromRawValue};
use dynasmrt::{dynasm, DynasmApi, AssemblyOffset};
use once_cell::sync::Lazy;

static ASSEMBLER: Lazy<RwLock<dynasmrt::x64::Assembler>> = Lazy::new(|| RwLock::new(dynasmrt::x64::Assembler::new().unwrap()));

fn build_wrapper(fn_name: String) -> usize {
    let mut ops = ASSEMBLER.write().unwrap();
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

    let executor = ops.reader();
    let buf = executor.lock();

    let file_name = format!("/tmp/perf-{}.map", std::process::id());
    let file = std::fs::OpenOptions::new().append(true).create(true).open(file_name).unwrap();

    let mut line_writer = std::io::LineWriter::new(file);
    let len = unsafe {buf.ptr(end_offset).offset_from(buf.ptr(asm_wrapper))};
    let perf_map = format!("{:x} {:x} {}\n", buf.ptr(asm_wrapper) as usize, len, fn_name);
    line_writer.write_all(perf_map.as_bytes()).unwrap();

    asm_wrapper.0
}

fn wrapper(fn_pointer: usize) -> magnus::Value {
    let fn_pointer = ASSEMBLER.read().unwrap().reader().lock().ptr(AssemblyOffset(fn_pointer));
    unsafe {
        let asm_wrapper_fn: extern "C" fn() -> rb_sys::Value =
            mem::transmute(fn_pointer);
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
