use std::{mem};

use cranelift::{prelude::{Signature, FunctionBuilderContext, FunctionBuilder, InstBuilder}};
use cranelift_module::{Module, Linkage};
use magnus::{define_module, function, rb_sys::FromRawValue};

fn generate_function(mut builder: FunctionBuilder) {
    // Create a new block.
    let block = builder.create_block();
    builder.append_block_params_for_function_params(block);

    // Create a signature for the external function rb_yield.
    let mut external_func_sig = Signature::new(cranelift::prelude::isa::CallConv::SystemV);
    external_func_sig.returns.push(cranelift::prelude::AbiParam::new(cranelift::prelude::types::I64));
    external_func_sig.params.push(cranelift::prelude::AbiParam::new(cranelift::prelude::types::I64));
    let sif_ref = builder.import_signature(external_func_sig);

    builder.switch_to_block(block);
    // prepare arguments for rb_yield
    let args = &[builder.ins().iconst(cranelift::prelude::types::I64, 0)];
    // load rb_yield function pointer
    let fn_ptr = builder.ins().iconst(cranelift::prelude::types::I64, rb_sys::rb_yield as usize as i64);
    // call rb_yield
    let result = builder.ins().call_indirect(
        sif_ref,
        fn_ptr,
        args,
    );

    // return rb_yield result
    let result = builder.inst_results(result)[0];
    builder.ins().return_(&[result]);
}

fn build_wrapper(fn_name: String) -> usize {
    let jit_builder = cranelift_jit::JITBuilder::new(cranelift_module::default_libcall_names()).unwrap();
    let mut jit_module = cranelift_jit::JITModule::new(jit_builder);
    let mut ctx = jit_module.make_context();

    ctx.func.signature.returns.push(cranelift::prelude::AbiParam::new(cranelift::prelude::types::I64));

    let mut fn_builder_ctx = FunctionBuilderContext::new();
    {
        let builder = FunctionBuilder::new(&mut ctx.func, &mut fn_builder_ctx);
        generate_function(builder);
    }

    let f_id = jit_module.declare_function(&fn_name, Linkage::Export, &ctx.func.signature).unwrap();
    jit_module.define_function(f_id, &mut ctx).unwrap();
    jit_module.finalize_definitions().unwrap();
    jit_module.get_finalized_function(f_id) as usize
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
