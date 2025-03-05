class Sale
  def self.find_all(html)
    html.search('table:contains("Withdrawal on")').map { new(it) }
  end

  def initialize(html)
    @html = html
    @sale_breakdown = html.next_element
  end

  def to_csv
    ['sale', date, number_of_shares, taxes_paid, cost_basis].join(",")
  end

  def date
    src = @html.at('td:contains("Settlement Date")').next_element
    day, month, year = src.text.strip.split('-')
    Time.utc(year, month, day).iso8601
  end

  def number_of_shares
    src = @html.at('td:contains("Shares Sold")').next_element
    src.text.strip.to_f
  end

  def taxes_paid = 0

  def cost_basis 
    src = @html.at('td:contains("Market Price Per Unit")').next_element
    src.text.gsub(/[^0-9.]/, '').to_f
  end
end
