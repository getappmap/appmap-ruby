#include <ruby.h>
#include <ruby/intern.h>

// Seems like CLASS_OR_MODULE_P should really be in a header file in
// the ruby source -- it's in object.c and duplicated in eval.c.  In
// the future, we'll fail if it does get moved to a header.
#define CLASS_OR_MODULE_P(obj) \
    (!SPECIAL_CONST_P(obj) && \
     (BUILTIN_TYPE(obj) == T_CLASS || BUILTIN_TYPE(obj) == T_MODULE))

#define ARITIES_KEY "__arities__"

VALUE am_AppMapHook;

static VALUE
singleton_method_owner_name(VALUE klass, VALUE method)
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


static VALUE
am_define_method_with_arity(VALUE mod, VALUE name, VALUE arity, VALUE proc)
{
  VALUE arities_key = rb_intern(ARITIES_KEY);
  VALUE arities = rb_ivar_get(mod, arities_key);
  
  if (arities == Qundef || NIL_P(arities)) {
    arities = rb_hash_new();
    rb_ivar_set(mod, arities_key, arities);
  }
  rb_hash_aset(arities, name, arity);

  return rb_funcall(mod, rb_intern("define_method"), 2, name, proc);
}

static VALUE
am_get_method_arity(VALUE method, VALUE orig_arity_method)
{
  VALUE owner = rb_funcall(method, rb_intern("owner"), 0);
  VALUE arities = rb_ivar_get(owner, rb_intern(ARITIES_KEY));
  VALUE name = rb_funcall(method, rb_intern("name"), 0);
  VALUE arity = Qnil;
  // See if we saved an arity for the method.
  if (!NIL_P(arities)) {
    arity = rb_hash_aref(arities, name);
  }
  // Didn't find one, call the original method.
  if (NIL_P(arity)) {
    VALUE bound_method = rb_funcall(orig_arity_method, rb_intern("bind"), 1, method);    
    arity = rb_funcall(bound_method, rb_intern("call"), 0);
  }

  return arity;
}

static VALUE
am_unbound_method_arity(VALUE method)
{
  VALUE orig_unbound_method_arity = rb_ivar_get(am_AppMapHook, rb_intern("@unbound_method_arity"));
  return am_get_method_arity(method, orig_unbound_method_arity);
}

static VALUE
am_method_arity(VALUE method)
{
  VALUE orig_method_arity = rb_ivar_get(am_AppMapHook, rb_intern("@method_arity"));
  return am_get_method_arity(method, orig_method_arity);
}

void Init_appmap() {
  VALUE appmap = rb_define_module("AppMap");
  am_AppMapHook = rb_define_class_under(appmap, "Hook", rb_cObject);

  rb_define_singleton_method(am_AppMapHook, "singleton_method_owner_name", singleton_method_owner_name, 1);

  rb_define_method(rb_cModule, "define_method_with_arity", am_define_method_with_arity, 3);
  rb_define_method(rb_cUnboundMethod, "arity", am_unbound_method_arity, 0);
  rb_define_method(rb_cMethod, "arity", am_method_arity, 0);
}
