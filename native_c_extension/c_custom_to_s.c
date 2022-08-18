#include "ruby.h"

// Defining a space for information and references about the module to be stored internally
VALUE CCustomToS = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_ccustomtos();

// Prototype for our methods, to be used by Init_ccustomtos
VALUE method_c_custom_to_s(VALUE, VALUE);

// The initialization method for this module
void Init_ccustomtos() {
  CCustomToS = rb_define_module("CCustomToS");
  rb_define_method(CCustomToS, "c_custom_to_s", method_c_custom_to_s, 1);
}

const int MAX_ARRAY_ENUMERATION = 10;
const int MAX_HASH_ENUMERATION = 10;
const int MAX_STRING_LENGTH = 100;

void method_c_custom_to_s_check_buffer_size(int offset, int string_len, int buffer_max) {
  if (offset + string_len > buffer_max) {
    // don't corrupt the buffer; throw exception
    rb_raise(rb_eRuntimeError, "method_c_custom_t_s_element would write %d bytes outside the buffer", buffer_max - offset - string_len);
  }
}

int method_c_custom_to_s_element(VALUE self, char *buffer, int *offset, VALUE element, int buffer_max) {
  VALUE element_to_s = method_c_custom_to_s(self, element);

  switch (TYPE(element_to_s)) {
  case T_NIL: {
    int string_len = 3; // + 1 for \0
    method_c_custom_to_s_check_buffer_size(*offset, string_len + 1, buffer_max);
    sprintf(&buffer[*offset], "nil");
    *offset += string_len;
    break;
  }
  case T_STRING: {
    VALUE element_to_s = method_c_custom_to_s(self, element);
    int string_len = RSTRING_LEN(element_to_s);
    // +2 for the two "s. + 1 for \0.
    method_c_custom_to_s_check_buffer_size(*offset, string_len + 3, buffer_max);
    sprintf(&buffer[*offset], "\"");
    *offset += 1;
    sprintf(&buffer[*offset], "%s", StringValueCStr(element_to_s));
    *offset += string_len;
    sprintf(&buffer[*offset], "\"");
    *offset += 1;
    break;
  }
  default: {
    // should never get here
    break;
  }
  }

  return 0;
}

VALUE method_c_custom_to_s_array(VALUE self, VALUE value) {
  VALUE ret;
  // the buffer max size should be "big enough" and it's indeterminate
  int buffer_max = MAX_STRING_LENGTH * MAX_ARRAY_ENUMERATION;
  char buffer[buffer_max];
  
  int array_len = RARRAY_LEN(value);
  int max_len = array_len;
  int offset = 0;
  int remaining_elements = 0;
  if (max_len > MAX_ARRAY_ENUMERATION) {
    remaining_elements = max_len - MAX_ARRAY_ENUMERATION;
    max_len = MAX_ARRAY_ENUMERATION;
  }

  sprintf(&buffer[offset], "[");
  offset += 1;
  int counter = 0;
  while (counter < max_len) {
    if (counter > 0) {
      sprintf(&buffer[offset], "%s", ", ");
      offset += 2;
    }

    VALUE array_element = rb_ary_entry(value, counter);
    method_c_custom_to_s_element(self, buffer, &offset, array_element, buffer_max);
    counter += 1;
  }

  if (remaining_elements > 0) {
    // create another buffer, to find the exact number of characters
    // printed by the indeterminate %d
    char buffer_small[128];
    sprintf(&buffer_small[0], " (...%d more items)", remaining_elements);
    int buffer_small_len = strlen(buffer_small);
    
    sprintf(&buffer[offset], buffer_small, buffer_small_len);
    offset += buffer_small_len;
    strcat(buffer, "]");
  } else {
    sprintf(&buffer[offset], "]");
    offset += 1;    
  }

  ret = rb_str_new_cstr(buffer);

  return ret;
}

struct method_c_custom_to_s_hash_iterator_state_s {
  VALUE self;
  int buffer_max;
  char *buffer;
  int *offset;
  int *counter;
  int max_len;
  int remaining_elements;
  char *remaining_elements_shown;
};

int method_c_custom_to_s_hash_iterator(VALUE key, VALUE val, VALUE arg) {
  struct method_c_custom_to_s_hash_iterator_state_s *state = (void *) arg;

  if (state->remaining_elements > 0) {
    if (state->remaining_elements_shown == 0) {
      char buffer_small[128];
      sprintf(&buffer_small[0], " (...%d more items)", state->remaining_elements);
      int buffer_small_len = strlen(buffer_small);

      sprintf(&state->buffer[*state->offset], buffer_small, buffer_small_len);
      *state->offset += buffer_small_len;

      *state->remaining_elements_shown = 1;
    }
  } else {
    if (*state->counter > 0) {
      sprintf(&state->buffer[*state->offset], "%s", ", ");
      *state->offset += 2;
    }
  
    method_c_custom_to_s_element(state->self, state->buffer, state->offset, key, state->buffer_max);

    sprintf(&state->buffer[*state->offset], "=>");
    *state->offset += 2;

    method_c_custom_to_s_element(state->self, state->buffer, state->offset, val, state->buffer_max);
  }

  *state->counter += 1;

  return 0;
}

// from http://clalance.blogspot.com/2011/01/writing-ruby-extensions-in-c-part-10.html
VALUE method_c_custom_to_s_hash(VALUE self, VALUE value) {
  VALUE ret;
  // the buffer max size should be "big enough" and it's indeterminate
  int buffer_max = MAX_STRING_LENGTH * MAX_HASH_ENUMERATION;
  char buffer[buffer_max];

  int hash_len = RHASH_SIZE(value);
  int max_len = hash_len;
  int offset = 0;
  int remaining_elements = 0;
  if (max_len > MAX_HASH_ENUMERATION) {
    remaining_elements = max_len - MAX_HASH_ENUMERATION;
    max_len = MAX_HASH_ENUMERATION;
  }

  sprintf(&buffer[offset], "{");
  offset += 1;


  int counter = 0;
  // pass state from this function into the callback function that
  // executes during each hash iteration
  struct method_c_custom_to_s_hash_iterator_state_s state;
  state.self = self;
  state.buffer_max = buffer_max;
  state.buffer = buffer;
  state.offset = &offset;
  state.counter = &counter;
  state.max_len = max_len;
  state.remaining_elements = remaining_elements;
  rb_hash_foreach(value, &method_c_custom_to_s_hash_iterator, (VALUE) &state);

  sprintf(&buffer[offset], "}");
  offset += 1;
  
  ret = rb_str_new_cstr(buffer);

  return ret;
}

// This is the method we added to test out passing parameters
// from https://silverhammermba.github.io/emberb/c/
VALUE method_c_custom_to_s(VALUE self, VALUE first) {
  VALUE ret;
  char buffer[MAX_STRING_LENGTH * 2];
  
  switch (TYPE(first)) {
  case T_NIL:
    ret = rb_str_new_cstr("");
    break;
  case T_TRUE:
    ret = rb_str_new_cstr("true");
    break;
  case T_FALSE:
    ret = rb_str_new_cstr("false");
    break;      
  case T_FIXNUM: {
    sprintf(buffer, "%ld", FIX2LONG(first));
    ret = rb_str_new_cstr(buffer);
    break;
  }
  case T_FLOAT: {
    sprintf(buffer, "%.15g", RFLOAT_VALUE(first));
    ret = rb_str_new_cstr(buffer);
    break;
  }
  case T_SYMBOL:
    sprintf(buffer, ":%s", rb_id2name(SYM2ID(first)));
    ret = rb_str_new_cstr(buffer);
    break;
  case T_STRING: {
    int len = RSTRING_LEN(first);
    int max_len = len;
    int remaining_characters = 0;
    if (max_len > MAX_STRING_LENGTH) {
      remaining_characters = max_len - MAX_STRING_LENGTH;
      max_len = MAX_STRING_LENGTH;
    }
    // max_len + 1 because it adds the NULL at the end too
    snprintf(buffer, max_len + 1, "%s", StringValueCStr(first));
    if (remaining_characters > 0)
      sprintf(&buffer[max_len], " (...%d more characters)", remaining_characters);
    ret = rb_str_new_cstr(buffer);
    break;
  }
  case T_ARRAY: {
    ret = method_c_custom_to_s_array(self, first);
    break;
  }
  case T_HASH: {
    ret = method_c_custom_to_s_hash(self, first);
    break;
  }
  case T_DATA:
    // captures Time, Date
  case T_FILE:
  case T_OBJECT: {
    // Net::HTTP
    // Net::HTTPGenericRequest
    ret = rb_funcall(self, rb_intern("custom_display_string_c_not_implemented"), 1, first);
    break;
  }
  default:
    break;
  }

  return ret;
}
