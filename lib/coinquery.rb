#!/usr/bin/env ruby

# file: coinquery.rb
# description: Uses the Coingecko API. Inspired by the coingecko_client gem

require 'c32'
require 'json'
require 'excon'
require 'unichron'
require 'did_you_mean'
require 'recordx_sqlite'



class CoinQueryException < Exception
end

class CoinQuery
  using ColouredText

  attr_reader :list

  def initialize(autofind: true, dym: true, timeout: 5, filepath: '.', 
                 debug: false)

    @autofind, @dym, @timeout, @debug = autofind, dym, timeout, debug
    @filepath = filepath

    @url_base = 'https://api.coingecko.com/api/v3/'
    r = ping()

    if r then

      puts ('CoinQuery').highlight + ' (powered by CoinGecko)'
      puts
      puts ('ping response: ' + r.to_a.first.join(' ')).info

      if autofind then

        file = 'coinquery.dat'

        if not File.exists? file then

          puts ('fetching coins list ...').info  
          @list = api_call 'coins/list'
        

          if @dym then

            puts 'loading did_you_mean ...'.info if @debug          

            @dym = DidYouMean::SpellChecker.new(dictionary: @list.flat_map \
                      {|x| [x['symbol'], x['name']]})
          end

        end


        if not File.exists? file then

          File.open(File.join(@filepath, file), 'w+') do |f|  
           Marshal.dump([@list, @dym], f)  
          end 

        else
        
          puts ('loading coins list ...').info  
          File.open(File.join(@filepath, file)) do |f|  
            @list, @dym = Marshal.load(f)  
          end
    
        end

      end
    end
    
    @table = RecordxSqlite.new(File.join(@filepath, 'coinquery.db'), 
      table: {coins: {id: '', cname: '', price: '', date: 0}})
    

  end
  
  # archives the cryptocurrency prices in a local sqlite database
  # note: intended for archiving prices on a daily basis
  # 
  def archive(limit: 250)    
        
    puts 'archive: fetching coins ...'.info
    a = coins(limit: limit)
    
    puts 'archive: saving to database ...'.info

    a.each do |coin|
      
      uid = coin['id'] + Date.today.to_time.to_i.to_s
      @table.create id: uid.to_s, cname: coin['name'], 
          price: coin['current_price'].to_s, date: Date.today.to_time.to_i
      
    end
    
    puts 'archive: completed'.info
    
  end

  # lists the top coins (limited to 5 by default)
  # 
  def coins(limit: 5)
    currency = 'usd'
    api_call "coins/markets?vs_currency=#{currency}&per_page=#{limit}"
  end

  # lists the names and identifiers of all coins
  #
  def coins_list
    @list
  end
  
  def find_coin(coin_name)

    return coin_name unless @autofind

    s = coin_name.to_s.downcase
    puts 's: ' + s.inspect if @debug
    r = @list.find {|coin| coin['symbol'].downcase == s || coin['name'].downcase == s}
    puts 'r: ' + r.inspect if @debug
    
    if r.nil? then

      if @dym then

        suggestion = @dym.correct coin_name
        raise CoinQueryException, "unknown coin or token name. \n"  \
            + "Did you mean %s?" % [suggestion.first]

      else

        raise CoinQueryException, "unknown coin or token name."

      end

    end

    r

  end

  def find_id(name)
    r = find_coin(name)
    r['id']
  end  
  
  def find_name(s)
    r = find_coin s
    r['name']
  end

  # returns the price of a coin for a given historical date
  # e.g. historical_price('Bitcoin', '01-05-2021')
  #
  def historical_price(coin, rawdate)

    uc = Unichron.new(rawdate.to_s, :little_endian)
    raise 'invalid date' unless uc.valid?
    date = uc.to_date.strftime("%d-%m-%Y")

    id = find_id coin
    r = api_call "coins/%s/history?date=%s" % [id, date]
    price = r['market_data']['current_price']['usd']
    price < 1 ? price : price.round(2)

  end

  alias history historical_price
  
  def ping
    api_call 'ping'
  end

  # returns the price for a given a coin
  # e.g. price('Litecoin')
  #
  def price(coin)

    currency = 'usd'
    id = find_id coin
    r = api_call("simple/price?ids=#{id}&vs_currencies=#{currency}")

    if r then
      val = r[id][currency]
      val < 1 ? val : val.round(2)
    end
  end
  
  # use the database archive to query the historical price of a coin
  # e.g. query_archive :btc, '1 May 2021'
  #
  def query_archive(coin_name, rawdate)

    uc = Unichron.new(rawdate.to_s, :little_endian)
    raise 'invalid date' unless uc.valid?
    date = uc.to_date
    
    coin_id = find_id coin_name    
    
    id = coin_id + date.to_time.to_i.to_s
    r = @table.query "select * from coins where id == '#{id}'"
    r.first if r
    
  end


  private

  def api_call(api_request)
    
    begin
      Timeout::timeout(@timeout){
        response = Excon.get(@url_base + api_request)
        JSON.parse(response.body)
      }
    rescue Timeout::Error => e
      raise CoinQueryException, 'connection timed out'
    rescue OpenURI::HTTPError => e
      raise CoinQueryException, '400 bad request'
    end

  end
  
end
