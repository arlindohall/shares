class TaxableEvents
  class Lot
    attr_reader :number_of_shares, :cost_basis, :acquisition_date
    attr_accessor :sale_price, :sale_date

    def initialize(number_of_shares:, cost_basis:, acquisition_date:, sale_price: nil, sale_date: nil)
      @number_of_shares = number_of_shares
      @cost_basis = cost_basis
      @acquisition_date = acquisition_date
      @sale_price = sale_price
      @sale_date = sale_date
    end

    def to_json
      {number_of_shares:, cost_basis:, acquisition_date:, sale_price:, sale_date:}.to_json
    end

    def long_term?
      sale_date - acquisition_date > SECONDS_IN_YEAR
    end

    def gains
      number_of_shares * (sale_price - cost_basis)
    end
  end

  class Account
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

    def debug
      warn "---"
      # warn "Lots..."
      # @lots.each { warn it.to_json }
      warn "Lots stil held..."
      lots_still_held.each { warn it.to_json }
    end

    private

    def track_vested_lots(event)
      return unless event.vest?
      @lots << Lot.new(
        number_of_shares: event.number_of_shares,
        cost_basis: event.cost_basis,
        acquisition_date: event.date,
      )
      @lots << Lot.new(
        number_of_shares: event.shares_sold_for_taxes,
        cost_basis: event.cost_basis,
        acquisition_date: event.date,
        sale_price: event.sale_price,
        sale_date: event.date,
      )
    end

    def track_sold_lots(event)
      return if event.vest?

      # warn "Looking for sold lots, sale_amt=#{event.number_of_shares}, ", lots_still_held.map(&:to_json)
      find_lots(event.number_of_shares).each do
        it.sale_date = event.date
        it.sale_price = event.sale_price
      end
    end

    def find_lots(number_of_shares)
      return oldest_first(number_of_shares) if oldest_first(number_of_shares)
      return exact_match(number_of_shares) if exact_match(number_of_shares)

      raise "Unable to determine lots sold by oldest-first policy or by matching lot size (lot_size=#{number_of_shares}) available lots:\n#{lots_still_held.map(&:to_json).join("\n")}"
    end

    def exact_match(number_of_shares)
      matches = @lots.filter { is_delta?(it.number_of_shares, number_of_shares) }
      # warn "Testing individual lots sale_amt=#{number_of_shares}, ", matches.map(&:to_json)

      matches.first if matches.size == 1
    end

    def oldest_first(number_of_shares)
      # warn "Lots still held, ", lots_still_held.map(&:to_json)
      lots_still_held.size.times do |batch_size|
        batch = lots_still_held.take(batch_size + 1)
        # warn "Testing batch: sale_amt=#{number_of_shares}, ", batch.map(&:to_json)

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

    account.sold_lots.sort_by(&:sale_date)
  end
end
