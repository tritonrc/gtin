module GS1
  module Prefixes

   begin
     require File.expand_path('../gs1_prefix_data.rb', __FILE__)
   rescue Exception
     puts "Please run get_prefix_data to generate 'gs1_prefix_data.rb'"
   end

   class << self
   def ean_to_country(ean)
      prefix = ean[0..2]
      GS1::PrefixData::PREFIXES_TO_COUNTRY.each do |p, c|
        return c if p.include?(prefix)
      end
      nil
    end

    def coupon?(ean)
      prefix = ean[0..2]
      GS1::PrefixData::COUPON_PREFIXES.include?(prefix)
    end

    def restricted?(ean)
      prefix = ean[0..2]
      GS1::PrefixData::RESTRICTED_PREFIXES.include?(prefix)
    end
 
    def issn?(ean)
      prefix = ean[0..2]
      GS1::PrefixData::ISSN_PREFIXES.include?(prefix)
    end
    alias_method :periodical?, :issn?

    def isbn?(ean)
      prefix = ean[0..2]
      GS1::PrefixData::ISBN_PREFIXES.include?(prefix)
    end
    alias_method :book?, :isbn?

    def refund?(ean)
      prefix = ean[0..2]
      GS1::PrefixData::REFUND_PREFIXES.include?(prefix)
    end

    #BTM - TODO: We need to add another list to gs1_prefix_data to cover this prefix
    #data fully
    def product?(ean)
      !coupon?(ean) and !refund?(ean) 
    end

    def get_prefix_data(out='gs1_prefix_data.rb', url='http://www.ean-int.org/barcodes/support/prefix_list')
      require 'rubygems'
      require 'uri' 
      require 'open-uri'
      require 'nokogiri'
      require 'iso_countries'
      require 'json'

      country_to_code = {}
      ISO::Countries::CODE_TO_COUNTRY.each_pair do |code, isc|
        country_to_code[isc] = code
      end

      valid_prefixes = []
      coupon_prefixes = []
      isbn_prefixes = []
      issn_prefixes = []
      restricted_prefixes = []
      refund_prefixes = []
      go_prefixes = []
      country_to_prefixes = {}
      country_to_lookup = {}

      document = Nokogiri::HTML(open(url))
      return if document.nil?
      document.search('table.idkeytable tr').each do |tr|
        tds = tr.search('td')
        next unless tds.any?
        prefix_range = tds[0].inner_text.scan(/[0-9]{3}/)
        prefixes = case prefix_range.length
          when 1 then prefix_range.first
          when 2 then Range.new(prefix_range[0], prefix_range[1], false).to_a
          else next
        end

        valid_prefixes << prefixes

        next if tds[1].nil?
        description = tds[1].inner_text.strip

        unless description.match(/^GS1 (.*)/).nil?
          case $1
            when "Global Office" then go_prefixes << prefixes
            else
              country = $1
              country = $1 unless country.match(/\((.*)\)/).nil?
              country = country.split(/,|&/).first.strip
              if country_to_code.key?(country)
                country_to_prefixes[country_to_code[country]] = [prefixes].flatten
              else
                if country_to_lookup.key?(country)
                  country_to_lookup[country] = country_to_lookup[country] << prefixes
                else
                  country_to_lookup[country] = [prefixes]
                end
              end
          end
        else
          description = description.downcase

          if description.include?('restricted')
            restricted_prefixes << prefixes
          end

          if description.include?('coupon')
            coupon_prefixes << prefixes
          end

          if description.include?('issn')
            issn_prefixes << prefixes
          end

          if description.include?('isbn')
            isbn_prefixes << prefixes
          end

          if description.include?('refund')
            refund_prefixes << prefixes
          end
        end
      end

      country_to_lookup.each_pair do |k, v|
        title = case k
          when "Czech" then "Czech Republic"
          when "Emirates" then "United Arab Emirates"
          else
            r = open("http://en.wikipedia.org/w/api.php?action=query&titles=#{URI::encode(k)}&format=json&redirects", 'User-Agent' => "Ruby/#{RUBY_VERSION}")
            json = JSON.parse(r.read)
            if json['query']['pages'].key?('-1')
              puts "#{k} not found in Wikipedia"
              next
            end

            page_id = json['query']['pages'].keys.first
            json['query']['pages'][page_id]['title']
        end

        if country_to_code.key?(title)
          country_to_prefixes[country_to_code[title]] = v.flatten
        else
          puts "#{k} -> #{title} not found in ISO countries"
          next
        end
      end

      mod = <<-delimiter
        module GS1
          module PrefixData
            VALID_PREFIXES = #{valid_prefixes.flatten}.freeze

            COUPON_PREFIXES = #{coupon_prefixes.flatten}.freeze

            ISBN_PREFIXES = #{isbn_prefixes.flatten}.freeze

            ISSN_PREFIXES = #{issn_prefixes.flatten}.freeze

            RESTRICTED_PREFIXES = #{restricted_prefixes.flatten}.freeze

            REFUND_PREFIXES = #{refund_prefixes.flatten}.freeze

            GO_PREFIXES = #{go_prefixes.flatten}.freeze

            COUNTRY_TO_PREFIXES = #{country_to_prefixes}.freeze

            PREFIXES_TO_COUNTRY = COUNTRY_TO_PREFIXES.inject({}) { |memo, kv| memo[kv[1]] = kv[0]; memo }.freeze
          end
        end
      delimiter

      File.open(out, "w") do |ios|
        ios.write(mod)
      end
    end
    end
  end
end
