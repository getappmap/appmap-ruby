#include "ruby.h"

// from https://silverhammermba.github.io/emberb/c/

// Defining a space for information and references about the module to be stored internally
VALUE CCustomTracepoint = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_ccustomtracepoint();

// Prototype for our methods, to be used by Init_ccustomtos
VALUE method_c_custom_trace_end_hook(VALUE, VALUE, VALUE, VALUE);

// The initialization method for this module
void Init_ccustomtracepoint() {
  CCustomTracepoint = rb_define_module("CCustomTracepoint");
  rb_define_method(CCustomTracepoint, "c_custom_trace_end_hook", method_c_custom_trace_end_hook, 3);
}

// implement hook.rb:trace_end_hook as a C module
VALUE method_c_custom_trace_end_hook(VALUE self, VALUE hook_cls, VALUE method_id, VALUE config) {
  // hook_cls:  Class  RUBY_T_CLASS  hook_cls or
  // hook_cls:  Module RUBY_T_MODULE hook_cls
  // method_id: Symbol RUBY_T_SYMBOL method_id
  // config:  Object RUBY_T_OBJECT config

  // TODO: wrap in begin/rescue/return
  VALUE method;
  method = rb_funcall(hook_cls, rb_intern("instance_method"), 1, method_id);

  /* printf("first   type is %d\n", TYPE(hook_cls)); */
  /* printf("second  type is %d\n", TYPE(method_id)); */
  /* printf("third   type is %d\n", TYPE(config)); */
  /* printf("method  type is %d\n", TYPE(method)); */

  VALUE package;
  package = rb_funcall(config, rb_intern("lookup_package"), 2, hook_cls, method);
  /* printf("package type is %d\n", TYPE(package)); */
  if (TYPE(package) == RUBY_T_NIL)
    return Qnil;

  rb_funcall(self, rb_intern("trace_end_hook_uncommon_path"), 4, hook_cls, method_id, method, package);

  return Qnil;
}
