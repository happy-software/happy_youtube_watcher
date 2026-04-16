module YoutubeWatcher
  # Gives you a simple interface to post a message to Slack
  module Slacker
    def self.post_message(message, channel)
      return unless Rails.env.production?
      return if message.empty?
      raise StandardError.new("Tried to post message to missing channel: (#{message})") if channel.empty?

      params = {
        text: message,
        channel: channel,
        icon_emoji: icon_emoji,
      }
      slack = Slack::Web::Client.new
      slack.chat_postMessage(params)
    end

    def self.icon_emoji
      # Symbols starting with digits or containing hyphens require quoted syntax (:"2ez", :"party-troll")
      emoji = [
        :"2ez", :"420", :"5head", :"99", :acknowledged, :afk, :alien_yeehaw, :allstar, :amaze,
        :"angry-cry-laugh-relatable", :angrycrylaugh, :aram, :aw_yeah, :aware, :ayy_lmao, :ayylmao,
        :"bald-man", :"bender-neat", :bongo_science_man, :bonezone, :"bosch-drill", :bowtie, :bruh,
        :bueller, :ceilingcat, :chatting, :check, :chef, :classic, :classic2, :clapping, :clueless,
        :conspiracy, :"cool-doge", :coolcry, :corona_but_not_the_virus, :corpa, :"crazy-troll",
        :cubimal_chick, :dab2, :dabmama, :dabmas, :dancing_dog, :dancetime, :dockerf, :done,
        :"double-plus", :dragonball, :"drake-helps", :dude_suh, :dusty_stick, :edm, :elmofire,
        :elmohype, :elon, :erbefe, :erbefe2, :erbefe3, :"fb-wow", :fidget_spinner, :flaming_thumbs_up,
        :flush, :forever_alone, :forsen1, :gg, :glitch_crab, :gran, :guitartime, :hecooking,
        :hehhehhehheh, :hmmm, :hmmmmmmmmm, :hmpf, :huhh, :iroh, :italian_kissy_fingers, :"just-saiyan",
        :kandel, :keruru, :large_amount_of_information_not_enough_time_to_read, :letmein, :letsgo,
        :letroll, :lfg, :lfg2, :lfg3, :litty, :lmaooo, :loading, :lol, :lolwut, :looking, :mad_yeehaw,
        :master_chief_thinking, :mother_of_god, :nani_pepe, :nerd2, :nice, :no2, :np, :nugtime,
        :"oi-aram", :"omg-cat", :oooo, :oof, :partyparrot, :"party-sadtroll", :"party-troll",
        :perfecto, :piggy, :"pizza-wave", :pls, :plz, :popcorntime, :poro, :pride, :pugdance,
        :raccoondance, :reallymad, :"relatable-content", :rip, :ripbozo, :roach, :sad_yeehaw,
        :sad_yeehaw_dab, :sadtroll, :seemsgood, :shaka, :shocked, :shpongle, :"shrek-umm",
        :sick_yeehaw, :simple_smile, :slack, :slack_call, :slippin, :slowpoke, :smart, :sniff,
        :socially_distanced_yeehaw, :spark_plug, :spidernice, :spinner, :squiddab, :squirrel,
        :suh_dude, :"super-thumb", :sussy, :teamwork, :tf, :themoreyouknow, :think, :think360,
        :thinking_yeehaw, :this, :thumbsup_all, :tired, :"top-performer", :trolldespair, :tru,
        :true, :tssk, :tums, :tux, :ty, :ubuntu, :vapeweedeveryday, :vegeta, :vegeta9000, :vibe,
        :welcome, :wfh_yeehaw, :whatblink, :winner, :word, :wot, :wow, :yay, :yeehaw, :yes, :zoinks
      ].sample

      ":#{emoji}:"
    end
  end
end
