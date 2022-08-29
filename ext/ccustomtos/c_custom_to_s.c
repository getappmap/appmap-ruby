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
const int MAX_EXPECTED_NESTED_LEVELS = 4;

#define ADD_CHAR(buffer, offset, value) \
{                                       \
  buffer[offset] = value;               \
  offset += 1;                          \
}                                       \

void method_c_custom_to_s_check_buffer_size(int offset, int string_len, int buffer_max) {
  if (offset + string_len > buffer_max) {
    // don't corrupt the buffer; throw exception
    rb_raise(rb_eRuntimeError, "method_c_custom_t_s_element would write %d bytes outside the buffer", offset + string_len - buffer_max);
  }
}

int method_c_custom_to_s_element(VALUE self, char *buffer, int *offset, VALUE element, int buffer_max, char quoted) {
  switch (TYPE(element)) {
  case T_NIL: {
    int string_len = 3; // +1 for NULL
    method_c_custom_to_s_check_buffer_size(*offset, string_len + 1, buffer_max);
    buffer[*offset] = 'n';
    *offset += 1;
    buffer[*offset] = 'i';
    *offset += 1;
    buffer[*offset] = 'l';
    *offset += 1;
    break;
  }
  case T_STRING: {
    VALUE element_to_s = method_c_custom_to_s(self, element);
    int string_len = RSTRING_LEN(element_to_s);
    // +2 for the two "s. +1 for NULL
    method_c_custom_to_s_check_buffer_size(*offset, string_len + 3, buffer_max);
    if (quoted)
      ADD_CHAR(buffer, *offset, '"');

    memcpy(&buffer[*offset], StringValuePtr(element_to_s), string_len);
    *offset += string_len;

    if (quoted)
      ADD_CHAR(buffer, *offset, '"');
    break;
  }
  default: {
    VALUE element_to_s = method_c_custom_to_s(self, element);
    method_c_custom_to_s_element(self, buffer, offset, element_to_s, buffer_max, 0);
    break;
  }
  }

  return 0;
}

VALUE method_c_custom_to_s_array(VALUE self, VALUE value) {
  VALUE ret;
  // the buffer max size should be "big enough" and it's indeterminate
  int buffer_max = MAX_STRING_LENGTH * MAX_ARRAY_ENUMERATION * MAX_EXPECTED_NESTED_LEVELS;
  char buffer[buffer_max];
  
  int array_len = RARRAY_LEN(value);
  int max_len = array_len;
  int offset = 0;
  int remaining_elements = 0;
  if (max_len > MAX_ARRAY_ENUMERATION) {
    remaining_elements = max_len - MAX_ARRAY_ENUMERATION;
    max_len = MAX_ARRAY_ENUMERATION;
  }

  // 2: for "[" and \0
  method_c_custom_to_s_check_buffer_size(offset, 2, buffer_max);
  ADD_CHAR(buffer, offset, '[');
  int counter = 0;
  while (counter < max_len) {
    if (counter > 0) {
      // 3: ", " and \0
      method_c_custom_to_s_check_buffer_size(offset, 3, buffer_max);
      buffer[offset] = ',';
      offset += 1;
      buffer[offset] = ' ';
      offset += 1;
    }

    VALUE array_element = rb_ary_entry(value, counter);
    method_c_custom_to_s_element(self, buffer, &offset, array_element, buffer_max, 1);
    counter += 1;
  }

  if (remaining_elements > 0) {
    // create another buffer, to find the exact number of characters
    // printed by the indeterminate %d
    char buffer_small[128];
    sprintf(&buffer_small[0], " (...%d more items)", remaining_elements);
    int buffer_small_len = strlen(buffer_small);

    // 2: for "]" and NULL
    method_c_custom_to_s_check_buffer_size(offset, buffer_small_len + 2, buffer_max);
    memcpy(&buffer[offset], buffer_small, buffer_small_len);
    offset += buffer_small_len;

    ADD_CHAR(buffer, offset, ']');
  } else {
    // 2: for "]" and NULL
    method_c_custom_to_s_check_buffer_size(offset, 2, buffer_max);
    ADD_CHAR(buffer, offset, ']');
  }

  buffer[offset] = '\0';
  ret = rb_str_new(buffer, offset);

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
  char remaining_elements_shown;
};

int method_c_custom_to_s_hash_iterator(VALUE key, VALUE val, VALUE arg) {
  struct method_c_custom_to_s_hash_iterator_state_s *state = (struct method_c_custom_to_s_hash_iterator_state_s *) arg;

  if (*state->counter < state->max_len) {
    if (*state->counter > 0) {
      // 3: ", " and NULL
      method_c_custom_to_s_check_buffer_size(*state->offset, 3, state->buffer_max);
      state->buffer[*state->offset] = ',';
      *state->offset += 1;
      state->buffer[*state->offset] = ' ';
      *state->offset += 1;
    }
    int buffer_key_max = MAX_STRING_LENGTH * 2;
    char buffer_key[buffer_key_max];
    int offset_key = 0;
    // hash values can be hashes themselves, so leave enough space for them
    int buffer_value_max = MAX_STRING_LENGTH * MAX_HASH_ENUMERATION * MAX_EXPECTED_NESTED_LEVELS;
    char buffer_value[buffer_value_max];
    int offset_value = 0;

    // build the key and the value separately, and either add them
    // together in a single step or stop adding if it would overflow
    // the buffer
    method_c_custom_to_s_element(state->self, buffer_key, &offset_key, key, buffer_key_max, 1);
    method_c_custom_to_s_element(state->self, buffer_value, &offset_value, val, buffer_value_max, 1);

    // +3 for "=>" and NULL
    if (*state->offset + offset_key + offset_value + 3 > state->buffer_max) {
      // stop adding: it would overflow the buffer
    } else {
      //printf("will add for offset_key %d\n", offset_key);
      memcpy(&state->buffer[*state->offset], buffer_key, offset_key);
      *state->offset += offset_key;
      state->buffer[*state->offset] = '=';
      *state->offset += 1;
      state->buffer[*state->offset] = '>';
      *state->offset += 1;
      memcpy(&state->buffer[*state->offset], buffer_value, offset_value);
      *state->offset += offset_value;
    }
  } else if (state->remaining_elements > 0) {
    if (state->remaining_elements_shown == 0) {
      char buffer_small[128];
      sprintf(&buffer_small[0], " (...%d more entries)", state->remaining_elements);
      int buffer_small_len = strlen(buffer_small);

      // +1 for NULL
      method_c_custom_to_s_check_buffer_size(*state->offset, buffer_small_len + 1, state->buffer_max);
      memcpy(&state->buffer[*state->offset], buffer_small, buffer_small_len);
      *state->offset += buffer_small_len;

      state->remaining_elements_shown = 1;
    }
  }

  *state->counter += 1;

  return 0;
}

// from http://clalance.blogspot.com/2011/01/writing-ruby-extensions-in-c-part-10.html
VALUE method_c_custom_to_s_hash(VALUE self, VALUE value) {
  VALUE ret;
  // the buffer max size should be "big enough" and it's indeterminate
  int buffer_max = MAX_STRING_LENGTH * MAX_HASH_ENUMERATION * MAX_EXPECTED_NESTED_LEVELS;
  char buffer[buffer_max];

  int hash_len = RHASH_SIZE(value);
  int max_len = hash_len;
  int offset = 0;
  int remaining_elements = 0;
  if (max_len > MAX_HASH_ENUMERATION) {
    remaining_elements = max_len - MAX_HASH_ENUMERATION;
    max_len = MAX_HASH_ENUMERATION;
  }

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
  state.remaining_elements_shown = 0;

  ADD_CHAR(buffer, offset, '{');
  rb_hash_foreach(value, &method_c_custom_to_s_hash_iterator, (VALUE) &state);

  // 2: "}" and \0
  method_c_custom_to_s_check_buffer_size(*state.offset, 2, state.buffer_max);
  ADD_CHAR(buffer, offset, '}');

  buffer[offset] = '\0';
  ret = rb_str_new(buffer, offset);

  return ret;
}

// This is the method we added to test out passing parameters
// from https://silverhammermba.github.io/emberb/c/
VALUE method_c_custom_to_s(VALUE self, VALUE first) {
  VALUE ret;
  int buffer_max = MAX_STRING_LENGTH * 2;
  char buffer[buffer_max];
  
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
  case T_SYMBOL: {
    char *name = (char *) rb_id2name(SYM2ID(first));
    int max_len = strlen(name);
    int offset = 0;
    // +1 for : +1 for NULL
    method_c_custom_to_s_check_buffer_size(offset, max_len + 2, buffer_max);
    buffer[offset] = ':';
    offset += 1;
    memcpy(&buffer[offset], name, max_len);
    offset += max_len;
    buffer[offset] = '\0';
    ret = rb_str_new(buffer, offset);
    break;
  }
  case T_STRING: {
    int max_len = RSTRING_LEN(first);
    int remaining_characters = 0;
    if (max_len > MAX_STRING_LENGTH) {
      remaining_characters = max_len - MAX_STRING_LENGTH;
      max_len = MAX_STRING_LENGTH;
    }
    // +1 for NULL
    method_c_custom_to_s_check_buffer_size(0, max_len + 1, buffer_max);
    int offset = 0;
    memcpy(buffer, StringValuePtr(first), max_len);
    offset += max_len;

    if (remaining_characters > 0) {
      char buffer_small[128];
      sprintf(&buffer_small[0], " (...%d more characters)", remaining_characters);
      int buffer_small_len = strlen(buffer_small);

      // +1 for NULL
      method_c_custom_to_s_check_buffer_size(offset, buffer_small_len + 1, buffer_max);
      memcpy(&buffer[offset], buffer_small, buffer_small_len);
      offset += buffer_small_len;
    }

    buffer[offset] = '\0';

    // this is 600%-900%x faster than calling Ruby but reports the error:
    // in `generate': source sequence is illegal/malformed utf-8 (JSON::GeneratorError)
    // ret = rb_utf8_str_new(buffer, offset);

    // call Ruby function to utf8 encode instead of encode in C
    VALUE string_unencoded = rb_str_new(buffer, offset);
    ret = rb_funcall(self, rb_intern("custom_display_string_c_encode_utf8"), 1, string_unencoded);
    /* VALUE input_string_encoding = rb_funcall(first, rb_intern("encoding"), 0); */
    /* ret = rb_funcall(string_unencoded, rb_intern("force_encoding"), 1, input_string_encoding); */

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
  case T_OBJECT:
    // Net::HTTP
    // Net::HTTPGenericRequest
  default: {
    ret = rb_funcall(self, rb_intern("custom_display_string_c_not_implemented"), 1, first);
    break;
  }
  }

  return ret;
}
