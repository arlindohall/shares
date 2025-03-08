class Args
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
        @delimiter = @argv.shift
      when '--strategy', '-s'
        raise 'Not implemented: strategies other than sell first'
      when '--report', '-r'
        @report = @argv.shift
      end
    end

    self
  end

  attr_reader :delimiter, :report
end
