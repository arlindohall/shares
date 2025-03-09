class Sale
  def self.find_all(html)
    html.search('table:contains("Withdrawal on")').map { new(it) }
  end

  def initialize(html)
    @html = html
    @sale_breakdown = html.next_element
  end

  def vest? = false

  def row = [
    'sale', date.iso8601_date, number_of_shares, nil, nil, sale_price
  ]

  def date
    src = @html.at('td:contains("Settlement Date")').next_element
    day, month, year = src.text.strip.split('-')
    Time.utc(year, month, day)
  end

  def number_of_shares
    src = @html.at('td:contains("Shares Sold")').next_element
    src.text.strip.to_f
  end

  def sale_price
    src = @html.at('td:contains("Market Price Per Unit")').next_element
    src.text.gsub(/[^0-9.]/, '').to_f
  end

  def brokerage_fees
    com = fees.at('td:contains("Brokerage Commission")').next_element
    sup = fees.at('td:contains("Supplemental Transaction Fee")').next_element
    wire = fees.at('td:contains("Wire Fee")').next_element

    [com, sup, wire]
      .map(&:text)
      .map { it.gsub(/[^0-9.]/, '').to_f }
      .sum
  end

  private

  def fees
    @html.next_element
  end
end
