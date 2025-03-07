class Report
  attr_reader :transactions, :taxable_event_history

  def initialize(transactions:, taxable_event_history:)
    @transactions = transactions
    @taxable_event_history = taxable_event_history
  end

  def summary
    by_year.each do |year, events|
      short_term = events.reject(&:long_term?)
      long_term = events.filter(&:long_term?)

      warn "=== Year #{year}"
      warn "Long term gains: #{long_term.map(&:gains).sum.truncate_dollars}"
      warn "Short term gains: #{short_term.map(&:gains).sum.truncate_dollars}"
    end
  end

  def transactions
    warn '--- Transactions'
    warn transactions.map(&:to_json)
  end

  def history
    warn '--- Taxable Events'
    warn taxable_event_history.map(&:to_json)
  end

  def full_report
    warn '--- Yearly report (ignoring wash)'
    by_year.each do |year, events|
      short_term = events.reject(&:long_term?)
      long_term = events.filter(&:long_term?)

      if short_term.any?
        warn "=== #{year} Short Term"
        warn short_term.map(&:to_json)
      end

      if long_term.any?
        warn "=== #{year} Long Term"
        warn long_term.map(&:to_json)
      end
    end
  end

  def by_year
    taxable_event_history.group_by { it.sale_date.year }
  end
end
