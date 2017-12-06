require "rate_limiter"

module DiscordMiddleware
  # Enum for specifying which event attribute should be used
  # for rate limiting, in order to have per-user, per-channel,
  # or a per-guild rate limit.
  enum RateLimiterKey
    UserID
    ChannelID
    GuildID
  end

  # Middleware for performing rate limiting on message events. Rate limiting
  # can be configured to be per-user, per-channel, or per-guild by passing
  # a `RateLimiterKey` option.
  #
  # If the client has a cache enabled, it will be
  # used to resolve the guild to be rate limited on.
  #
  # If `message` contains the substring `"%time%"` it will be replaced
  # with the remaining time until the rate limit expires.
  # ```
  # limiter = RateLimiter(UInt64).new
  #
  # # Limit 3 events per second
  # limiter.bucket(:foo, 3_u32, 1.seconds)
  #
  # middleware = DiscordMiddleware::RateLimiter.new(
  #   limiter,
  #   :foo,
  #   DiscordMiddleware::RateLimiterKey::ChannelID
  #   "Slow down! Try again in %time%."
  # )
  #
  # client.stack(:memes, middleware) do |context|
  #   # Post memes, but not too quickly per-channel
  # end
  # ```
  class RateLimiter < Discord::Middleware
    def initialize(@limiter : ::RateLimiter(UInt64), @bucket : Symbol,
                   @key : RateLimiterKey = RateLimiterKey::UserID,
                   @message : String? = nil)
    end

    private def resolve_guild(context)
      if cache = context.client.cache
        channel = cache.resolve_channel(context.message.channel_id)
        if guild_id = channel.guild_id
          cache.resolve_guild(guild_id)
        end
      else
        channel = context.client.get_channel(context.message.channel_id)
        if guild_id = channel.guild_id
          context.client.get_guild(guild_id)
        end
      end
    end

    private def rate_limit_reply(context, time)
      if message = @message
        content = message.gsub("%time%", time.to_s)
        context.client.create_message(context.message.channel_id, content)
      end
    end

    def call(context, done)
      case key = @key
      when RateLimiterKey::UserID
        if time = @limiter.rate_limited?(@bucket, context.message.author.id)
          rate_limit_reply(context, time)
          return
        end
      when RateLimiterKey::ChannelID
        if time = @limiter.rate_limited?(@bucket, context.message.channel_id)
          rate_limit_reply(context, time)
          return
        end
      when RateLimiterKey::GuildID
        if guild = resolve_guild(context)
          if time = @limiter.rate_limited?(@bucket, context.message.channel_id)
            rate_limit_reply(context, time)
            return
          end
        end
      end

      done.call
    end
  end
end
