class Report
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

  class TransactionReport
    def self.headers = %w[
      Type
      Date
      Number_of_shares
      Shares_sold_for_taxes
      Cost_basis
      Sale_price
    ]

    def initialize(transactions)
      @transactions = transactions
    end

    def puts
      ReportBuilder.new(self.class, @transactions).build_and_puts
    end
  end

  class TaxableEventList
    def self.headers = %w[
      Number_of_shares
      Cost_basis
      Acquisition_date
      Sale_price
      Sale_date
      Long_term_equity?
    ]

    def self.column_widths = [
      17, 11, 17, 11, 12, 18
    ]

    def initialize(taxable_event_history)
      @taxable_event_history = taxable_event_history
    end

    def puts
      ReportBuilder.new(
        self.class,
        @taxable_event_history
          .sort_by { [it.sale_date.to_i, it.acquisition_date.to_i] }
      ).build_and_puts
    end
  end

  class YearlyReport
    def self.headers = [
      'Quantity',
      'Date_acquired',
      'Date_sold',
      'Proceeds',
      'Cost_basis',
      'Wash_sale_loss_disallowed',
      'Check_if_not_allowed',
      'Long_term/_short_term'
    ]

    def initialize(year, events)
      @year = year
      @events = events
    end

    def totals_table(short_term, long_term)
      short_term = %i[proceeds cost gains].map do |field|
        short_term.map(&field).sum.truncate_dollars.to_s.ljust(20)
      end.join
      long_term = %i[proceeds cost gains].map do |field|
        long_term.map(&field).sum.truncate_dollars.to_s.ljust(20)
      end.join

      <<~TABLE.strip.then { Args.delimiter ? it.gsub(/(  +)/, Args.delimiter) : it }
        --- Totals ---
        Type                                  Proceeds            Cost_basis          Gains
        short_term                            #{short_term}
        long_term                             #{long_term}
      TABLE
    end

    def puts
      warn <<~HEADER
        =============================
        === YEAR SUMMARY #{@year} ===
        =============================
      HEADER
      warn totals_table(short_term, long_term)
      warn(<<~WASH_TABLE.then { Args.delimiter ? it.gsub(/(  +)/, Args.delimiter) : it })
        --- Net short-term gains/losses ---
        Type                                  Amount
        long_term_wash_losses                 #{long_term.filter(&:is_wash).map(&:gains).filter(&:negative?).sum.truncate_dollars}
        short_term_wash_losses                #{short_term.filter(&:is_wash).map(&:gains).filter(&:negative?).sum.truncate_dollars}
        long_term_non_wash_losses             #{long_term.reject(&:is_wash).map(&:gains).filter(&:negative?).sum.truncate_dollars}
        short_term_non_wash_losses            #{short_term.reject(&:is_wash).map(&:gains).filter(&:negative?).sum.truncate_dollars}
        long_term_gains                       #{long_term.map(&:gains).filter(&:positive?).sum.truncate_dollars}
        short_term_gains                      #{short_term.map(&:gains).filter(&:positive?).sum.truncate_dollars}
      WASH_TABLE

      warn <<~HEADER

        === 1099 Fields for sales since tracking started ===
            This includes sell-to-cover (because acquisition_date is known)
        --- Reported: short term (should match 1099) ---
      HEADER
      ReportBuilder.new(
        self.class,
        short_term.filter(&:reporting_era?).map(&:yearly_report_event)
      ).build_and_puts
      warn totals_table(short_term.filter(&:reporting_era?), long_term.filter(&:reporting_era?))

      warn <<~HEADER
        --- Reported: long term (should match 1099) ---
      HEADER
      ReportBuilder.new(
        self.class,
        long_term.filter(&:reporting_era?).map(&:yearly_report_event)
      ).build_and_puts

      warn <<~HEADER

        === 1099 Fields for sales before tracking started, reported on 1099 as "Undetermined holdin period" ===
            These will not have a cost basis reported, and should be reoprted as short/long term based on the lot they were acquired from
            Note: to report as a loss, it must not be a "wash" sale (every sale is a wash if you vest monthly)
            Note: you can carry-over wash losses, but you must report them as such on each year of taxes until you have a year that's not a wash
        --- Unreported (proceeds should match, cost basis is missing) ---
      HEADER
      ReportBuilder.new(
        self.class,
        sorted_yearly_events.reject(&:reporting_era?).map(&:yearly_report_event)
      ).build_and_puts
      warn totals_table(short_term.reject(&:reporting_era?), long_term.reject(&:reporting_era?))
    end

    def sorted_yearly_events
      @events
        .sort_by { [it.sale_date.to_i, it.acquisition_date.to_i] }
    end

    def long_term
      @events.filter(&:long_term?)
    end

    def short_term
      @events.reject(&:long_term?)
    end
  end

  attr_reader :transactions, :taxable_event_history

  def initialize(transactions:, taxable_event_history:)
    @transactions = transactions
    @taxable_event_history = taxable_event_history
  end

  def all_transactions
    TransactionReport.new(transactions).puts
  end

  def history
    TaxableEventList.new(taxable_event_history).puts
  end

  def full_report
    if Args.report_year
      YearlyReport.new(Args.report_year, by_year[Args.report_year]).puts
    else
      last_year = by_year.keys.max # For formatting
      by_year
        .sort_by { |year, _events| year }
        .each do |year, events|
        YearlyReport.new(year, events).puts
        break if year == last_year

        warn ''
      end
    end
  end

  def by_year
    taxable_event_history.group_by { it.sale_date.year }
  end
end
