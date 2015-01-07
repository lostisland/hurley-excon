require "minitest/autorun"
require "hurley"
require "hurley/test"
require "hurley/test/integration"
require File.expand_path("../../lib/hurley-excon", __FILE__)

module HurleyExcon
  class Test < MiniTest::Test
    Hurley::Test::Integration.apply(self)

    def connection
      @connection ||= HurleyExcon::Connection.new
    end
  end
end
