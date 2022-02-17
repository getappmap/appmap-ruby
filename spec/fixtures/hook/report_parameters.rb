
class ReportParameters
  def to_s; self.class.name; end

  def report_parameters(*args, kw1:, kw2: 'kw2', **kws)
    method(:report_parameters).parameters
  end
end
