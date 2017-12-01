require "../spec_helper"

describe DiscordMiddleware::Error do
  describe "#initialize" do
    it "accepts a string" do
      DiscordMiddleware::Error.new("foo")
    end

    it "accepts a block" do
      DiscordMiddleware::Error.new { |ctx| nil }
    end
  end

  describe "#call" do
    it "calls the next middleware" do
      mw = DiscordMiddleware::Error.new("foo")
      context = Discord::Context.new(Client, message)

      mw.call(context, ->{ true }).should be_true
    end

    context "when the next middleware raises" do
      it "forwards the exception" do
        mw = DiscordMiddleware::Error.new { }
        context = Discord::Context.new(Client, message)

        expect_raises do
          mw.call(context, ->{ raise "exception" })
        end
      end

      context "when given a block" do
        it "calls it" do
          called = false
          mw = DiscordMiddleware::Error.new { called = true }
          context = Discord::Context.new(Client, message)

          begin
            mw.call(context, ->{ raise "exception" })
          rescue
          end

          called.should be_true
        end
      end

      context "when the next middleware doesn't raise" do
        context "when given a block" do
          it "doesn't call it" do
            called = false
            mw = DiscordMiddleware::Error.new { called = true }
            context = Discord::Context.new(Client, message)

            begin
              mw.call(context, ->{ "OK" })
            rescue
            end

            called.should be_falsey
          end
        end
      end
    end
  end
end
