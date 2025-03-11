class YearlyReportEvent
  attr_reader :quantity, :date_acquired, :date_sold, :proceeds, :cost_or_other_basis, :wash_sale_loss_disallowed,
              :check_if_loss_not_allowed

  def initialize(quantity:, date_acquired:, date_sold:, proceeds:, cost_or_other_basis:, wash_sale_loss_disallowed:,
                 check_if_loss_not_allowed:)
    @quantity = quantity
    @date_acquired = date_acquired
    @date_sold = date_sold
    @proceeds = proceeds
    @cost_or_other_basis = cost_or_other_basis
    @wash_sale_loss_disallowed = wash_sale_loss_disallowed
    @check_if_loss_not_allowed = check_if_loss_not_allowed
  end

  def self.headers = %w[
    Quantity
    Date_acquired
    Date_sold
    Proceeds
    Cost_or_other_basis
    Wash_sale_loss_disallowed
    Check_if_not_allowed
  ]

  def row = [
    quantity,
    date_acquired,
    date_sold,
    proceeds,
    cost_or_other_basis,
    wash_sale_loss_disallowed,
    check_if_loss_not_allowed
  ]
end
