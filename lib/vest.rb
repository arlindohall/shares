class Vest
  def self.find_all(html)
    html.search('table:contains("Share Units - Release")').map { new(it) }
  end

  def initialize(html)
    @html = html
  end

  def vest? = true

  def row = [
    'vest', date.iso8601_date, number_of_shares, shares_sold_for_taxes, cost_basis, sale_price
  ]

  def date
    src = @html.at('td:contains("Release Date")').next_element
    day, month, year = src.text.strip.split('-')
    Time.utc(year, month, day)
  end

  def settlement_date
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

  def grant_date
    src = @html.at('td:contains("Grant Date")').next_element
    day, month, year = src.text.strip.split('-')
    Time.utc(year, month, day)
  end

  def brokerage_fees
    com = fees.at('td:contains("Brokerage Commission")').next_element
    sup = fees.at('td:contains("Supplemental Transaction Fee")').next_element

    [com, sup]
      .map(&:text)
      .map { it.gsub(/[^0-9.]/, '').to_f }
      .sum
  end

  private

  def fees
    @html.next_element
  end
end
