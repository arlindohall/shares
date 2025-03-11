class ReportBuilder
  def initialize(report, data, out: STDERR)
    @report = report
    @data = data
    @out = out
  end

  def build_and_puts
    rows = @data.map do |datum|
      datum.row.map do |col|
        next(col) unless col.is_a?(Numeric)

        col.truncate_dollars
      end.map(&:to_s)
    end
    printable_rows = [@report.headers] + rows
    column_widths = printable_rows
                    .map { |row| row.map(&:to_s).map(&:size) }
                    .transpose
                    .map { [it.max + 1] }
                    .transpose
                    .flatten

    case Args.delimiter
    when 'tv'
      column_widths = column_widths.map { (it / 8.0).ceil * 8 }
      @out.puts(@report.headers.zip(column_widths).map { |col, w| tab_just(col, w) }.join)
      rows.each { @out.puts(it.zip(column_widths).map { |cell, w| tab_just(cell, w) }.join) }
    when 's'
      @out.puts(@report.headers.zip(column_widths).map { |col, w| space_just(col, w, is_header: true) }.join)
      rows.each { @out.puts(it.zip(column_widths).map { |cell, w| space_just(cell, w) }.join) }
    else
      @out.puts(@report.headers.join(Args.delimiter_char))
      rows.each { @out.puts(it.join(Args.delimiter_char)) }
    end
  end

  private

  def space_just(content, width, is_header: false)
    return content.ljust(width) if is_header

    content.rjust(width - 1).ljust(width)
  end

  def tab_just(content, width)
    tabs = "\t" * ((width - content.size) / 8.0).ceil
    "#{content}#{tabs}"
  end
end
