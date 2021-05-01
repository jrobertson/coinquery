# Introducing the CoinQuery gem

    require 'coinquery'

    cq = CoinQuery.new

    a = cq.coins
    a.each do |coin|
      puts "%+12s: %s" % [coin['name'], coin['current_price']]
    end

<pre>
     Bitcoin: 57668
    Ethereum: 2930.74
Binance Coin: 622.56
         XRP: 1.57
      Tether: 1.0
</pre>

    cq.price :solana
    #=> 48.17

    cq.historical_price :eth, '28 April 2021'
    #=> 2647.16  

    cq.coins_list.length
    #=> 6983

## Resources

* coinquery https://rubygems.org/gems/coinquery
* excon https://github.com/excon/excon
* coingecko https://github.com/fbohz/coingecko
* coinmarketcap https://github.com/ankitsamarthya/coinmarketcap
* CoinGecko API V3 https://www.coingecko.com/api/documentations/v3#

coinquery crypto coinmarketcap coingecko cryptocurrency bitcoin gem
