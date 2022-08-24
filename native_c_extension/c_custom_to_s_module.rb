# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'ccustomtos'

# The destination
dir_config(extension_name)

def ruby_version
  version = `rbenv prefix`.strip.split('/')[-1]
  version[0..2]
end

p "ruby_version: " + ruby_version
$LDFLAGS += " -L" + `rbenv prefix`.strip + "/lib -lruby" + ruby_version + " "
p "LDFLAGS:      " + $LDFLAGS

# Do the work
create_header
create_makefile(extension_name)
