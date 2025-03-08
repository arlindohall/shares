# Run with "ruby parse.rb"

require 'json'
require 'nokogiri'

require_relative 'lib/args'
require_relative 'lib/vest'
require_relative 'lib/report'
require_relative 'lib/sale'
require_relative 'lib/taxable_events'

SECONDS_IN_YEAR = 525_600 * 60

html = Nokogiri(File.read('input/adjusted-full-web.html'))

transactions = [Vest, Sale]
               .flat_map { |cls| cls.find_all(html) }
               .sort_by(&:date)

# Monkey patch floats to get money
class Numeric
  def truncate_dollars
    (self * 100).floor.to_f / 100
  end
end

# Monkey patch date with dumb formatter
class Time
  def iso8601_date
    [year, month.to_s.rjust(2, '0'), day.to_s.rjust(2, '0')].join('-')
  end
end

report = Report.new(
  transactions: transactions,
  taxable_event_history: TaxableEvents.new(transactions).history
)

case Args.report
when 'history'
  report.history
when 'transactions'
  report.all_transactions
when 'full', 'full_report', nil
  report.full_report
else
  raise "Unknown report type #{Args.report}"
end
