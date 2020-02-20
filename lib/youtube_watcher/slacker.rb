module YoutubeWatcher
  module Slacker
    def self.post_message(message, channel)
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
      # Just the essentials for now ayylmao
      s = [:ayylmao, :ayy_lmao, :bruh, :ceilingcat, :chef, :clapping, :dab2, :dabmas, :dude_suh, :elon, :erbefe2,
       :fidget_spinner, :gran, :italian_kissy_fingers, :kappa, :lolwut, :mother_of_god, :nani_pepe, :okaychamp, :pepega,
       :pepelaugh, :shaka, :slippin, :squiddab, :suh_dude, :teamwork, :vapeweedeveryday, :vegeta, :wutface].sample

      ":#{s}:"
    end
  end
end
