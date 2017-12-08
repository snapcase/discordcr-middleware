# This middleware evaluates the permissions of the calling message author.
#
# If the message is from a guild, the guilds roles and the current channels
# permissions will be taken into account according to the members roles.
# Otherwise, `DM_PERMISSIONS` will be considered.
#
# If the client has a cache enabled, it will be used to fetch the guild
# and channel.
#
# ```
# # Require that a user has permission to kick members to trigger this
# # handler
# perms = Discord::Permissions::KickMembers
#
# client.stack(:kick, PREFIX, DiscordMiddleware::Permissions.new(perms)) do |ctx|
#   # Kick 'em
# end
# ```
class DiscordMiddleware::Permissions < Discord::Middleware
  # The permissions a user has in a direct message
  DM_PERMISSIONS = Discord::Permissions.flags(
    ManageChannels,
    AddReactions,
    ReadMessages,
    SendMessages,
    SendTTSMessages,
    EmbedLinks,
    AttachFiles,
    ReadMessageHistory,
    MentionEveryone,
    UseExternalEmojis,
    Connect,
    Speak,
    UseVAD
  )

  def initialize(@permissions : Discord::Permissions)
  end

  private def get_guild(client : Discord::Client, guild_id : UInt64)
    if cache = client.cache
      cache.resolve_guild(guild_id)
    else
      client.get_guild(guild_id)
    end
  end

  private def get_channel(client : Discord::Client, channel_id : UInt64)
    if cache = client.cache
      cache.resolve_channel(channel_id)
    else
      client.get_channel(channel_id)
    end
  end

  private def get_member(client : Discord::Client, guild_id : UInt64,
                         member_id : UInt64)
    if cache = client.cache
      cache.resolve_member(guild_id, member_id)
    else
      client.get_guild_member(guild_id, member_id)
    end
  end

  def call(context, done)
    channel = get_channel(context.client, context.message.channel_id)
    user_id = context.message.author.id

    if guild_id = channel.guild_id
      guild = get_guild(context.client, guild_id)

      # Pass if the user is the owner of the guild
      return done.call if guild.owner_id == user_id

      member = get_member(context.client, guild_id, user_id)
      permissions = Discord::Permissions::None

      # Evaluate role permissions
      guild.roles.each do |r|
        permissions |= r.permissions if member.roles.includes?(r.id) || r.id == guild_id
      end

      # Pass if user has an administrator role
      return done.call if permissions.administrator?

      # Evaluate channel overwrites
      if overwrites = channel.permission_overwrites
        # @everyone
        overwrites.find { |o| o.id == guild_id }.try do |o|
          permissions &= ~o.deny
          permissions |= o.allow
        end

        # Role overwrites
        overwrites.select { |o| o.type == "role" && o.id != guild_id }.each do |o|
          permissions &= ~o.deny
          permissions |= o.allow
        end

        # User specific overwrites
        overwrites.find { |o| o.type == "user" && o.id == user_id }.try do |o|
          permissions &= ~o.deny
          permissions |= o.allow
        end
      end

      done.call if (@permissions & permissions) == @permissions
    else
      done.call if (@permissions & DM_PERMISSIONS) == @permissions
    end
  end
end
