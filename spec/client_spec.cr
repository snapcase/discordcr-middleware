require "./spec_helper"

describe Discord::Client do
  describe "#stacks" do
    it "holds a collection of Stacks" do
      Client.stacks.should be_a Hash(Symbol, Discord::Stack)
    end
  end

  describe "#stack" do
    context "with ID and middlewares" do
      it "stores a new stack" do
        c = Client
        c.stack(:foo, FlagMiddleware.new)
        c.stacks[:foo].should be_a Discord::Stack
      end

      it "forwards a block to the stack" do
        c = Client
        c.stack(:foo, FlagMiddleware.new) do |context|
          nil
        end

        c.stack(:foo).block?.should be_true
      end
    end

    context "with only ID" do
      it "returns the stack with that ID" do
        c = Client
        stack = c.stack(:foo, FlagMiddleware.new)
        c.stack(:foo).should eq stack
      end
    end
  end

  describe "#run_stack" do
    context "with only a message" do
      it "passes a message through each stack" do
        middlewares = {FlagMiddleware.new, FlagMiddleware.new}
        c = Client
        c.stack(:foo, *middlewares)
        c.stack(:bar, *middlewares)

        m = message
        c.run_stack(m)

        middlewares.each do |mw|
          mw.message.should eq m
          mw.counter.should eq 2
        end
      end
    end

    context "with an ID and message" do
      it "runs a specific stack" do
        c = Client
        mw = FlagMiddleware.new
        c.stack(:foo, mw)
        c.run_stack(:foo, message)

        mw.called.should be_true
      end
    end
  end
end
