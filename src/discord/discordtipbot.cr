require "raven"
require "logger"
require "pg"
require "pg/pg_ext/big_decimal"
require "discordcr"
require "big"
require "big/json"
require "discordcr-middleware"

require "../data/**"

require "../common/amount"
require "../common/coin_api"
require "../common/string_split"
require "../common/raven_spawn"

require "./**"

class DiscordTipBot
  def self.run
    log = Logger.new(STDOUT)

    Raven.configure do |raven_config|
      raven_config.async = true
    end

    Raven.capture do
      # Set your log level here
      log.level = Logger::DEBUG

      log.debug("Tipbot network getting started")

      shared_cache = Discord::Cache.new(Discord::Client.new(""))

      log.debug("starting forking")

      Data::Coin.read.each do |coin|
        raven_spawn(name: "#{coin.name_short} Bot") do
          token = coin.discord_token
          raise "Missing Discord Token" unless token
          bot = Discord::Client.new(token)
          cache = Discord::Cache.new(bot)
          shared_cache.bind(cache)
          bot.cache = cache

          DiscordBot.new(coin, bot, cache, log).run
        end
      end
      log.debug("finished forking")

      log.info("All bots should be running now")
    end
    sleep
  end
end