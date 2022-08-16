#include "ruby.h"

// Defining a space for information and references about the module to be stored internally
VALUE CCustomTracepoint = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_ccustomtracepoint();

// Prototype for our methods, to be used by Init_ccustomtos
VALUE method_c_custom_tracepoint(VALUE, VALUE);

// The initialization method for this module
void Init_ccustomtracepoint() {
  CCustomTracepoint = rb_define_module("CCustomTracepoint");
  rb_define_method(CCustomTracepoint, "c_custom_tracepoint", method_c_custom_tracepoint, 1);
}

// This is the method we added to test out passing parameters
// from https://silverhammermba.github.io/emberb/c/
VALUE method_c_custom_tracepoint(VALUE self, VALUE first) {
  return rb_str_new_cstr("tracepoint");
}
