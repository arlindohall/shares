class Sale
  def self.find_all(html)
    html.search('table:contains("Withdrawal on")').map { new(it) }
  end

  def initialize(html)
    @html = html
    @sale_breakdown = html.next_element
  end

  def to_json
    {type: 'sale', date: date.iso8601, number_of_shares:, sale_price:}.to_json
  end

  def vest? = false

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
end
