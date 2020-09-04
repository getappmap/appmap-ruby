require "mkmf"

$CFLAGS='-Werror'
extension_name = "appmap"
dir_config(extension_name)
create_makefile(File.join(extension_name, extension_name))
