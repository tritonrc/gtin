module EAN
  MIN_GS1_PREFIX_LENGTH = 7
  MAX_GS1_PREFIX_LENGTH = 9
  NUMERIC_REGEX = %r{[^0-9]{8,13}}.freeze
  EVENS = [0,2,4,6,8,10].freeze
  ODDS = [1,3,5,7,9].freeze

  class << self
    def valid?(code)
      return false unless code.is_a?(String)
      return false unless [8,12,13].include?(code.length)
      return false unless NUMERIC_REGEX.match(code).nil?
      code = self.to_upc(code)
      compute_check_digit(code[0..-2]) == code[-1..-1].to_i
    end

    def expand(code)
      case code.length
        when 6,8 then '0' + self.expand_upc_e(code)
        when 12 then '0' + code
        when 13 then code
        else raise InvalidArgument, 'EAN/UPC must be 6,8,12 or 13 digits long'
      end
    end

    def expand_upc_e(ean)
      raise InvalidArgument, 'UPC-E must be 6 or 8 digits long' unless [6,8].include?(ean.length)
      ean = ean[1..6] if ean.length == 8
      case ean[-1..-1].to_i
        when 0 then self.append_check_digit("0#{ean[0..1]}00000#{ean[2..4]}")
        when 1 then self.append_check_digit("0#{ean[0..1]}10000#{ean[2..4]}")
        when 2 then self.append_check_digit("0#{ean[0..1]}20000#{ean[2..4]}")
        when 3 then self.append_check_digit("0#{ean[0..2]}00000#{ean[3..4]}")
        when 4 then self.append_check_digit("0#{ean[0..3]}00000#{ean[4]}")
        when 5..9 then self.append_check_digit("0#{ean[0..4]}0000#{ean[-1]}")
      end
    end

    def compute_check_digit(ean)
      eands = ean.split('').map { |d| d.to_i }
      evens = eands.values_at(*EVENS).compact
      odds = eands.values_at(*ODDS).compact
      result = (evens.inject { |sum, n| sum + n } * 3 + odds.inject { |sum, n| sum + n }).modulo(10)
      result.zero? ? 0 : (10 - result)
    end

    def append_check_digit(ean)
      "#{ean}#{self.compute_check_digit(ean)}"
    end

    def to_upc(ean)
      return ean if ean.length != 13
      return ean unless ean[0..0] == '0'
      return ean[1..12]
    end
  end
end
