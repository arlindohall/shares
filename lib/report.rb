class Report
  class TransactionReport
    def initialize(transactions)
      @transactions = transactions
    end

    def puts
      ReportBuilder.new(Vest, @transactions).build_and_puts
    end
  end

  class TaxableEventList
    def initialize(taxable_event_history)
      @taxable_event_history = taxable_event_history
    end

    def puts
      ReportBuilder.new(
        Lot,
        @taxable_event_history
          .sort_by { [it.sale_date.to_i, it.acquisition_date.to_i] }
      ).build_and_puts
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
