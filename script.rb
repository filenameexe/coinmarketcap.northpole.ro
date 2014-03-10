#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'nokogiri'
require 'pp'

current_folder = File.dirname(File.expand_path(__FILE__))
@path = File.join(current_folder, 'public', 'api')

@doc = Nokogiri::HTML(open("http://coinmarketcap.com/all.html"))
# File.open('coinmarketcap','w') {|f| @doc.write_html_to f}
# @doc = Nokogiri::HTML(File.open('coinmarketcap', 'r'))

@ts = Time.now.to_i

# order is important
@keys = ['position', 'name', 'marketCap', 'price', 'totalSupply', 'volume24', 'change24', 'timestamp', 'currency', 'id']

def write_to_disk currency
  r = []
  @doc.css("#currencies tbody tr").each do |tr|
    tds = tr.css('td')

    # TODO clean this up
    begin
      td2 = tds[2].attribute("data-#{currency}").text.strip
    rescue
      td2 = ''
    end
    begin
      td3 = tds[3].css('a').attribute("data-#{currency}").text.strip
    rescue
      td3 = ''
    end
    begin
      td5 = tds[5].css('a').attribute("data-#{currency}").text.strip
    rescue
      td5 = ''
    end

    coin = [
      tds[0].text.strip,
      tds[1].text.strip,
      td2,
      td3,
      tds[4].text.strip.gsub('*', ''),
      td5,
      tds[6].text.strip,
      @ts,
      currency,
      ''
    ]
    coin[-1] = tr.attribute('id').text
    h = Hash[@keys.zip(coin)]

    File.open("#{@path}/#{coin[-1]}.json",'w') { |f| f.write(h.to_json) } if currency == 'usd'

    currency_path = "#{@path}/#{currency}/#{coin[-1]}.json"
    File.open("#{@path}/first_crawled/#{coin[-1]}.json",'w') { |f| f.write(h.to_json) } if !File.exists?(currency_path) && currency == 'usd'
    File.open(currency_path,'w') { |f| f.write(h.to_json) }

    r << h
  end

  rr = { 'timestamp' => @ts, 'markets' => r }
  File.open("#{@path}/all.json",'w') {|f| f.write(rr.to_json) } if currency == 'usd'
  File.open("#{@path}/#{currency}/all.json",'w') {|f| f.write(rr.to_json) }
end

write_to_disk 'usd'
write_to_disk 'btc'
