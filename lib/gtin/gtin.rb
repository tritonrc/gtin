module GTIN
  NUMERIC_REGEX = %r{[^0-9]{8,14}}.freeze
  EVENS, ODDS = *(0.upto(16).partition { |i| (i & 1) == 1}.map { |a| a.freeze })

  class << self
    # Determines whether the given code is a valid UPC-E, UPC-A, EAN-13 or
    # GTIN-14
    def valid?(code)
      return false unless code.is_a?(String)
      return false unless [8,12,13,14].include?(code.length)
      return false unless NUMERIC_REGEX.match(code).nil?
      compute_check_digit(code[0..-2]) == code[-1..-1].to_i
    end

    # Expands the given code to an EAN-13 or GTIN-14
    # This function will not shink a given code
    def expand(code, size = 13)
      length = code.length
      return code if length == 14
      ean13 = case length
        when 8 then '0' + expand_upc_e(code)
        when 12 then '0' + code
        when 13 then code
      end
      (size == 14) ? ('0' + ean13) : ean13
    end

    # Expands the given code to an EAN-13
    def to_gtin_13(code)
      expand(code, 13)
    end
    alias :to_ean :to_gtin_13

    # Expands the given code to a GTIN-14
    def to_gtin_14(code)
      expand(code, 14)
    end
    alias :to_gtin :to_gtin_14

    # Expands an eight-digit UPC-E to a twelve-digit UPC-A
    def expand_upc_e(upc)
      raise ArgumentError, 'UPC-E must be 8 digits long' unless upc.length == 8
      upc = upc[1..6]
      case upc[-1..-1].to_i
        when 0 then append_check_digit("0#{upc[0..1]}00000#{upc[2..4]}")
        when 1 then append_check_digit("0#{upc[0..1]}10000#{upc[2..4]}")
        when 2 then append_check_digit("0#{upc[0..1]}20000#{upc[2..4]}")
        when 3 then append_check_digit("0#{upc[0..2]}00000#{upc[3..4]}")
        when 4 then append_check_digit("0#{upc[0..3]}00000#{upc[4]}")
        when 5..9 then append_check_digit("0#{upc[0..4]}0000#{upc[-1]}")
      end
    end

    # Given a code without a check-digit, computes the check-digit
    def compute_check_digit(code, symbology = :ean)
      length = code.length
      leader = length - 12
      if length < 12
        symbology = :upc
      elsif code[0..leader] == '0' * (leader + 1)
        code = code[1..-1]
        symbology = :upc
      end

      digits = code.split('').map { |d| d.to_i }
      evens = digits.values_at(*(symbology == :ean ? EVENS : ODDS)).compact
      odds = digits.values_at(*(symbology == :ean ? ODDS : EVENS)).compact
      result = (evens.inject { |sum, n| sum + n } * 3 + odds.inject { |sum, n| sum + n }).modulo(10)
      result.zero? ? 0 : (10 - result)
    end

    # Shrinks a US prefixed EAN-13 or GTIN-14 to UPC-A
    def to_upc(gtin)
      length = gtin.length
      return gtin unless [13, 14].include?(length)
      leader_size = length - 12
      return gtin unless gtin[0..leader_size] == '0' * (leader_size + 1)
      gtin[leader_size..-1]
    end

    def append_check_digit(body)
      "#{body}#{compute_check_digit(body)}"
    end
  end
end
