class Lot
  attr_reader :number_of_shares, :cost_basis, :acquisition_date, :grant_date, :brokerage_fees, :is_for_tax
  attr_accessor :sale_price, :sale_date, :is_wash, :is_lte

  def initialize(number_of_shares:, cost_basis:, grant_date:, acquisition_date:, brokerage_fees:, is_for_tax:, sale_price: nil,
                 sale_date: nil)
    @number_of_shares = number_of_shares
    @cost_basis = cost_basis
    @grant_date = grant_date
    @acquisition_date = acquisition_date
    @brokerage_fees = brokerage_fees
    @is_for_tax = is_for_tax
    @sale_price = sale_price
    @sale_date = sale_date
  end

  def yearly_report_event = YearlyReportEvent.new(
    quantity: number_of_shares,
    date_acquired: acquisition_date.iso8601_date,
    date_sold: sale_date.iso8601_date,
    proceeds: proceeds,
    cost_or_other_basis: cost,
    wash_sale_loss_disallowed: [proceeds - cost, 0].min,
    check_if_loss_not_allowed: is_wash
  )

  def self.headers = %w[
    Number_of_shares
    Cost_basis
    Acquisition_date
    Sale_price
    Sale_date
    Long_term_equity?
  ]

  def row = [
    number_of_shares,
    cost_basis,
    acquisition_date.iso8601_date,
    sale_price,
    sale_date.iso8601_date,
    brokerage_fees,
    is_lte
  ]

  def long_term?
    sale_date - acquisition_date > SECONDS_IN_YEAR
  end

  def gains
    gross - cost
  end

  def proceeds
    gross - brokerage_fees
  end

  def gross
    number_of_shares * sale_price
  end

  def cost
    number_of_shares * cost_basis
  end

  def reporting_era?
    # This is how MS defined shares that WILL NOT be tracked
    return true if is_for_tax

    acquisition_date >= Time.utc(2024, 7, 25)
  end
end
