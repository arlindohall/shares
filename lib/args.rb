class Args
  DELIMITERS = {
    ',' => ',',
    't' => "\t"
  }
  def self.method_missing(name, *_args)
    @instance ||= new.parse!
    return @instance.send(name) if @instance.methods.include?(name)

    raise "Unknown arg #{name}"
  end

  def initialize(argv = ARGV)
    @argv = argv.dup
  end

  def parse!
    until @argv.empty?
      case arg = @argv.shift
      when '--delimiter', '-d'
        delimiter_name = @argv.shift
        @delimiter = DELIMITERS[delimiter_name] || (raise "Invalid delmiter name#{delimiter_name}")
      when '--strategy', '-s'
        raise 'Not implemented: strategies other than fifo with fallback to exact_match'
      when '--report', '-r'
        @report = @argv.shift
        @report_year = @argv.shift.to_i if @argv.first && @argv.first&.match(/\d{4}/)
      when '--help', '-h'
        help
        abort
      else
        usage "Unrecognized argument: #{arg}"
      end
    end

    self
  end

  def usage(message)
    warn message
    warn 'Usage: parse.rb [--help | --delimiter <delim> | --strategy <strat> | --report <rep> (year)]'
    abort
  end

  def help
    warn <<~USAGE
      Usage: parse.rb [args]

      Arguments:
        --help, -h                  Show this message

        --delimiter <delim>         Required parameter delim is used to delimit fields
        -d <delim>                    in the output, e.g. to get csv output use
                                      `parse.rb -d ,`

        --strategy <strat>          Use a pre-defined strategy to choose which stocks to
        -s <strat>                    sell in each transaction. Must be one of:
                                      exact_match, fifo, lifo, any_matching_subset.

        --report <rep> [year]       Output a specific type of report. If [year] (optional)
        -r <rep> [year]               is provided, then the full report is only given for
                                      sales in the year provided.

      STRATEGIES can be:
        exact_match: If you only sold individual lots in every transaction since the
        beginning of time, you can assume every sale will correspond to one vest and one
        vest date. This option makes that assumption, and bombs if a sale every does not
        match.

        fifo: Build lots on sale from the oldest to the newest, taking as many full lots
        as needed to build a batch exactly the size of the sale. If there are not enough
        (error in input or program logic) or too many (violation of the assumptions of
        this algo), will error.

        -- The following are not yet implemented...

        lifo: Sell newest shares first, otherwise same as fifo

        fifo_partial: Same as fifo, but allow sales of partial lots

        any_matching_subset: Every sale must match exactly some whole set of lots, but
        there is no restriction on order. Will throw an error if it can construct more than
        one group of lots that exactly equal the desired amount

      REPORTS can be:
        transactions: simply format the parsed input, no info that's not also in the
        report.html

        history: translate every transaction into a sale, and sales that happened on the
        same day are split into separate lots if purchased/ vested separately

        full, full_report: roughly a 1099 equivalent. IANA accountant, so take this with
        a grain of salt.
    USAGE
  end

  attr_reader :delimiter, :report, :report_year
end
