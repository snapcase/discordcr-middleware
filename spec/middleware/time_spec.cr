require "../spec_helper"

describe DiscordMiddleware::Time do
  describe "#initialize" do
    it "accepts a time span with a block" do
      block = ->(ctx : Discord::Context) {}
      mw = DiscordMiddleware::Time.new(5.seconds, &block)
      mw.@delay.should eq 5.seconds
      mw.@block.should eq block
    end
  end

  describe "#call" do
    it "calls the next middleware right away" do
      mw = DiscordMiddleware::Time.new(5.milliseconds) { |ctx| true }
      msg = message
      context = Discord::Context.new(Client, msg)

      mw.call(context, ->{ true }).should be_true
    end

    it "calls the block after the time has elapsed" do
      called = false
      mw = DiscordMiddleware::Time.new(5.milliseconds) { |ctx| called = true }
      msg = message
      context = Discord::Context.new(Client, msg)

      mw.call(context, ->{ true })
      called.should be_false

      sleep 6.milliseconds
      called.should be_true
    end
  end
end
