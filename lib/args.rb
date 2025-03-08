class Args
  def self.method_missing(name, *_args) = new.parse!.send(name)

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
      end
    end

    self
  end

  attr_reader :delimiter
end
