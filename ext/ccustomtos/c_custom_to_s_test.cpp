// 1) This file has the extension .cpp so that the makefile for the
// native extension doesn't automatically compile it and include it in
// the final .so.

// 2) The .so file wasn't getting loaded dynamically with
// 'require', so I included the C source code directly.
#include "c_custom_to_s.c"


VALUE method_c_custom_to_s(VALUE self, VALUE first);
  
int main() {
  ruby_init();

  VALUE self;
  VALUE data_str_8 = rb_str_new_cstr("12345678");
  /* VALUE data_str_16 = rb_str_new_cstr("1234567890123456"); */

  // int state;
  // rb_eval_string_protect(
  //   "\n"
  //   "filename = Dir.getwd + '/ccustomtos'\n"
  //   "p filename\n"
  //   //"require filename\n"
  //   //"require Dir.getwd + '/ccustomtos'\n"
  //   //"include CCustomToSs"
  //   "p 'Hello, world!'\n"
  //   "p 'more'\n"
  //   , &state);

  printf("out here\n");
  VALUE ret = method_c_custom_to_s(self, data_str_8);

  return ruby_cleanup(0);
}
