# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'ccustomtos'

# The destination
dir_config(extension_name)

def ruby_version
  version = `rbenv prefix`.strip.split('/')[-1]
  if version[0..3] == 'ruby'
    # ie: ruby-2.5.8
    version.split('-')[-1][0..2]
  else
    # ie: 3.0.1
    version[0..2]
  end
end

p "rbenv_prefix: " + `rbenv prefix`.strip
p "ruby_version: " + ruby_version
$LDFLAGS += " -L" + `rbenv prefix`.strip + "/lib -lruby" + ruby_version + " "
p "LDFLAGS:      " + $LDFLAGS

# Do the work
create_header
create_makefile(extension_name)
