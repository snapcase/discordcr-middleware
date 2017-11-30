require "../spec_helper"

describe DiscordMiddleware::Conditional do
  describe "#initialize" do
    it "takes a block that returns a bool" do
      mw = DiscordMiddleware::Conditional.new ->(ctx : Discord::Context) { true }
      mw.@condition.should be_a Proc(Discord::Context, Bool)
    end
  end

  describe "#call" do
    mw = DiscordMiddleware::Conditional.new ->(ctx : Discord::Context) do
      ctx.message.content == "!ping"
    end

    context "when truthy" do
      it "calls the next middleware" do
        msg = message("!ping")
        context = Discord::Context.new(Client, msg)

        mw.call(context, ->{ true }).should be_true
      end
    end

    context "when falsey" do
      it "doesn't call the next middleware" do
        msg = message("!pong")
        context = Discord::Context.new(Client, msg)

        mw.call(context, ->{ true }).should be_falsey
      end
    end
  end
end
