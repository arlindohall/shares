# Run with "ruby parse.rb"

require 'json'
require 'nokogiri'

require_relative 'lib/vest'
require_relative 'lib/sale'
require_relative 'lib/taxable_events'

SECONDS_IN_YEAR = 525_600 * 60

html = Nokogiri(File.read('input/adjusted-full-web.html'))

transactions = [Vest, Sale]
               .flat_map { |cls| cls.find_all(html) }
               .sort_by(&:date)

warn '--- Transactions'
warn transactions.map(&:to_json)

taxable_event_history = TaxableEvents.new(transactions).history
warn '--- Taxable Events'
warn taxable_event_history.map(&:to_json)

warn '--- Yearly report (ignoring wash)'
taxable_event_history.group_by { it.sale_date.year }
                     .each do |year, events|
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
