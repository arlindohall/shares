class Vest
  def self.find_all(html)
    html.search('table:contains("Share Units - Release")').map { new(it) }
  end

  def initialize(html)
    @html = html
    @shares_sold = html.next_element
  end

  def to_csv
    ['vest', date, number_of_shares, taxes_paid, cost_basis].join(',')
  end

  def date
    src = @html.at('td:contains("Settlement Date")').next_element
    day, month, year = src.text.strip.split('-')
    Time.utc(year, month, day).iso8601
  end

  def number_of_shares
    src = @html.at('td:contains("Number of Restricted Awards Disbursed")').next_element
    src.text.strip.to_f
  end

  def taxes_paid
    src = @html.at('td:contains("Number of Restricted Awards Sold")').next_element
    src.text.strip.to_f * cost_basis
  end

  def cost_basis
    src = @html.at('td:contains("Sale Price")').next_element
    src.text.gsub(/[^0-9.]/, '').to_f
  end
end
