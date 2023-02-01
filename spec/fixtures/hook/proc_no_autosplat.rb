# Since ruby 3.2, a proc that accepts a single positional argument and
# keywords will no longer autosplat.
class ProcNoAutosplat
  class << self
    def proc_no_autosplat(params)
      proc{|a, **k| a}.call(params)
    end
  end
end
