#include <ruby.h>
#include <ruby/intern.h>

// Seems like CLASS_OR_MODULE_P should really be in a header file in
// the ruby source -- it's in object.c and duplicated in eval.c.  In
// the future, we'll fail if it does get moved to a header.
#define CLASS_OR_MODULE_P(obj) \
    (!SPECIAL_CONST_P(obj) && \
     (BUILTIN_TYPE(obj) == T_CLASS || BUILTIN_TYPE(obj) == T_MODULE))

static VALUE singleton_method_owner_name(VALUE klass, VALUE method)
{
  VALUE owner = rb_funcall(method, rb_intern("owner"), 0);
  VALUE attached = rb_ivar_get(owner, rb_intern("__attached__"));
  if (!CLASS_OR_MODULE_P(attached)) {
    attached = rb_funcall(attached, rb_intern("class"), 0);
  }

  // Did __attached__.class return an object that's a Module or a
  // Class?
  if (CLASS_OR_MODULE_P(attached)) {
    // Yup, get it's name
    return rb_mod_name(attached);
  }

  // Nope (which seems weird, but whatever). Fall back to calling
  // #to_s on the method's owner and hope for the best.
  return rb_funcall(owner, rb_intern("to_s"), 0);
}
    
void Init_appmap() {
  VALUE appmap = rb_define_module("AppMap");
  VALUE hook = rb_define_class_under(appmap, "Hook", rb_cObject);

  rb_define_singleton_method(hook, "singleton_method_owner_name", singleton_method_owner_name, 1);
}
