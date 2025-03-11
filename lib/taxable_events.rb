class TaxableEvents
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
