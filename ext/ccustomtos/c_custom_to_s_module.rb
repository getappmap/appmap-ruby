# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'ccustomtos'

# The destination
dir_config(extension_name)

$LDFLAGS += " -L" + `rbenv prefix`.strip + "/lib "
p "LDFLAGS:      " + $LDFLAGS

# Do the work
create_header
create_makefile(extension_name)
