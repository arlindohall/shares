class YearlyReport
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

    <<~TABLE.strip.then { Args.delimiter ? it.gsub(/(  +)/, Args.delimiter_char) : it }
      --- Totals ---
      Type                                  Proceeds            Cost_basis          Gains
      short_term                            #{short_term}
      long_term                             #{long_term}
    TABLE
  end

  # TODO: Split into separate reports with names so they can be saved as multiple csv files or as
  # an excel spreadsheet with multiple tabs
  def puts
    warn <<~HEADER
      =============================
      === YEAR SUMMARY #{@year} ===
      =============================
    HEADER
    warn totals_table(short_term, long_term)
    warn(<<~WASH_TABLE.then { Args.delimiter ? it.gsub(/(  +)/, Args.delimiter_char) : it })
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
      YearlyReportEvent,
      short_term.filter(&:reporting_era?).map(&:yearly_report_event)
    ).build_and_puts
    warn totals_table(short_term.filter(&:reporting_era?), long_term.filter(&:reporting_era?))

    warn <<~HEADER
      --- Reported: long term (should match 1099) ---
    HEADER
    ReportBuilder.new(
      YearlyReportEvent,
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
      YearlyReportEvent,
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
