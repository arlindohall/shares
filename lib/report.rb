class Report
  class ReportBuilder
    def initialize(report, data, out: STDERR, additional_headers: nil)
      @report = report
      @data = data
      @out = out
      @additional_headers = additional_headers
    end

    def build_and_puts
      @out.puts @additional_headers if @additional_headers

      if Args.delimiter
        build_and_puts_delimited
        return
      end

      @out.puts(@report.headers.zip(@report.column_widths).map { |col, w| col.ljust(w) }.join)

      @data.each do |datum|
        @out.puts(datum.row.zip(@report.column_widths).map do |col, w|
          value = col.is_a?(Numeric) ? col.truncate_dollars : col
          value.to_s.rjust(w - 1).ljust(w)
        end.join)
      end
    end

    def build_and_puts_delimited
      @out.puts(@report.headers.join(Args.delimiter))
      @data.each do |datum|
        @out.puts(
          datum.row.map do |col|
            col.is_a?(Numeric) ? col.truncate_dollars : col
          end.join(Args.delimiter)
        )
      end
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

    def self.column_widths = [
      6, 11, 17, 22, 11, 11
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
    ]

    def self.column_widths = [
      17, 11, 17, 11, 12
    ]

    def initialize(taxable_event_history)
      @taxable_event_history = taxable_event_history
    end

    def puts
      ReportBuilder.new(self.class, @taxable_event_history).build_and_puts
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

    def self.column_widths = [
      12, 14, 12, 12, 12, 26, 21, 22
    ]

    def initialize(year, events)
      @year = year
      @events = events
    end

    def puts
      ReportBuilder.new(
        self.class,
        @events.map(&:yearly_report_event),
        additional_headers: <<~HEADER
          === YEAR SUMMARY #{@year} ===
          Total short term: #{short_term.map(&:gains).sum.truncate_dollars}
          Total long term: #{long_term.map(&:gains).sum.truncate_dollars}
          --- YEAR DETAILS ---
        HEADER
      ).build_and_puts
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
    by_year.each do |year, events|
      YearlyReport.new(year, events).puts
    end
  end

  def by_year
    taxable_event_history.group_by { it.sale_date.year }
  end
end
