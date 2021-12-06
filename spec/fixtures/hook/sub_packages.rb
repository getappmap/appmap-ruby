require_relative 'pkg_a/a'

module SubPackages
  def self.invoke_a
    PkgA::A.hello
  end
end
