require 'yaml'

require 'server'
require 'client'
require 'character'
require 'fight'
require 'object'
require 'script'
require 'room'
require 'area'

class Mud
  def initialize
    Area.load_all

    @server = Server.new
    @server.start
  end
end

if __FILE__ == $0
  $mud = Mud.new
end
