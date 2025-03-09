class TaxableEvents
  class YearlyReportEvent
    attr_reader :lot

    def initialize(lot)
      @lot = lot
    end

    def row = [
      lot.number_of_shares,
      lot.acquisition_date.iso8601_date,
      lot.sale_date.iso8601_date,
      lot.proceeds,
      lot.cost,
      [lot.proceeds - lot.cost, 0].min,
      lot.is_wash,
      lot.long_term? ? :long_term_gains : :short_term_gains
    ]
  end

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

    def long_term?
      sale_date - acquisition_date > SECONDS_IN_YEAR
    end

    def yearly_report_event = YearlyReportEvent.new(self)

    def row = [
      number_of_shares,
      cost_basis,
      acquisition_date.iso8601_date,
      sale_price,
      sale_date.iso8601_date,
      brokerage_fees,
      is_lte
    ]

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

  class Account
    THIRTY_DAYS_SECONDS = 3600 * 24 * 30

    def initialize
      @lots = []
    end

    def <<(event)
      track_vested_lots(event)
      track_sold_lots(event)
    end

    def sold_lots
      @lots - lots_still_held
    end

    def compute_lte_and_wash
      @lots.each do |lot|
        lot.is_wash = @lots.any? do |other|
          next false if lot.sale_date.nil?

          (other.acquisition_date - lot.sale_date).abs < THIRTY_DAYS_SECONDS
        end

        # TODO: Should be able to tell if LTE because the number of shares will be the same as
        # a batch of vests going back to the grant date, vs for quarterly, will be same as
        # the quarter's worth of shares, and grant date will be within three months
        lot.is_lte = 'unknown'
      end
    end

    private

    def track_vested_lots(event)
      return unless event.vest?

      @lots << Lot.new(
        number_of_shares: event.number_of_shares,
        cost_basis: event.cost_basis,
        acquisition_date: event.date,
        grant_date: event.grant_date,
        brokerage_fees: event.brokerage_fees,
        is_for_tax: false
      )
      @lots << Lot.new(
        number_of_shares: event.shares_sold_for_taxes,
        cost_basis: event.cost_basis,
        acquisition_date: event.date,
        grant_date: event.grant_date,
        brokerage_fees: event.brokerage_fees,
        is_for_tax: true,
        sale_price: event.sale_price,
        sale_date: event.date
      )
    end

    def track_sold_lots(event)
      return if event.vest?

      find_lots(event.number_of_shares).each do
        it.sale_date = event.date
        it.sale_price = event.sale_price
      end
    end

    def find_lots(number_of_shares)
      return oldest_first(number_of_shares) if oldest_first(number_of_shares)
      return exact_match(number_of_shares) if exact_match(number_of_shares)

      raise <<~MESSAGE
        Unable to determine lots sold by oldest-first policy or by matching lot size (lot_size=#{number_of_shares}) available lots:
          #{Report::TaxableEventList.headers}
          #{lots_still_held.map(&:row).join("\n")}
      MESSAGE
    end

    def exact_match(number_of_shares)
      matches = @lots.filter { is_delta?(it.number_of_shares, number_of_shares) }

      matches.first if matches.size == 1
    end

    def oldest_first(number_of_shares)
      lots_still_held.size.times do |batch_size|
        batch = lots_still_held.take(batch_size + 1)

        return batch if is_delta?(batch.map(&:number_of_shares).sum, number_of_shares)
      end

      nil
    end

    def lots_still_held
      @lots.filter { it.sale_date.nil? }
    end

    def is_delta?(a, b)
      (a - b).abs < 0.01
    end
  end

  def initialize(transactions)
    @transactions = transactions.sort_by(&:date)
  end

  def history
    account = Account.new

    @transactions.each do |transaction|
      account << transaction
    end

    account.compute_lte_and_wash

    account.sold_lots.sort_by(&:sale_date)
  end
end
