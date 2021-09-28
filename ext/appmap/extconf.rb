require "mkmf"


$CFLAGS='-Werror'

# Per https://bugs.ruby-lang.org/issues/17865,
# compound-token-split-by-macro was added in clang 12 and broke
# compilation with some of the ruby headers. If the current compiler
# supports the new warning, turn it off.
new_warning = '-Wno-error=compound-token-split-by-macro'
if try_cflags(new_warning)
  $CFLAGS += ' ' + new_warning
end

extension_name = "appmap"
dir_config(extension_name)
create_makefile(File.join(extension_name, extension_name))
