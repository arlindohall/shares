class Vest
  def self.find_all(html)
    html.search('table:contains("Share Units - Release")').map { new(it) }
  end

  def initialize(html)
    @html = html
  end

  def to_json
    {type: 'vest', date: date.iso8601, number_of_shares:, shares_sold_for_taxes:, cost_basis:, sale_price:}.to_json
  end

  def vest? = true

  def date
    src = @html.at('td:contains("Settlement Date")').next_element
    day, month, year = src.text.strip.split('-')
    Time.utc(year, month, day)
  end

  def number_of_shares
    src = @html.at('td:contains("Number of Restricted Awards Disbursed")').next_element
    src.text.strip.to_f
  end

  def shares_sold_for_taxes
    src = @html.at('td:contains("Number of Restricted Awards Sold")').next_element
    src.text.strip.to_f
  end

  def cost_basis
    src = @html.at('td:contains("Release Price")').next_element
    src.text.gsub(/[^0-9.]/, '').to_f
  end

  def sale_price
    src = @html.at('td:contains("Sale Price")').next_element
    src.text.gsub(/[^0-9.]/, '').to_f
  end
end
