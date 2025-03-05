# Run with "ruby parse.rb"

require 'nokogiri'
require_relative 'lib/vest'
require_relative 'lib/sale'

html = Nokogiri(File.read('input/adjusted-full-web.html'))

transactions = [Vest, Sale]
               .flat_map { |cls| cls.find_all(html) }
               .sort_by(&:date)

puts transactions.map(&:to_csv)
