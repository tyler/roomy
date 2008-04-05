require 'client/meta_commands'
require 'client/commands'

# Client instances are created by the single server instance running for the MUD.
# A Client instance is created, and registered with the Class. When disconnecting
# Client#destroy is called, thus unregistering it with the Client Class.
class Mud
  class Client
    class << self
      attr_reader :clients

      def delete(client)
        @clients.delete(client)
      end

      def register(client)
        @clients ||= []
        @clients << client
      end

      def message_all(message)
        @clients.each {|c| c.message(message)}
      end

      def find_by_character(name)
        name = name.downcase
        @clients.find{|c| c.character.name.downcase == name}
      end

      def connect(session)
        Thread.new(session) do |session|
          begin
            client = self.new(session)

            client.message("Hey man.  Sup?")

            client.login

            until session.closed? || session.eof? do
              input = session.gets.chomp
              client.commands.dispatch(input)
            end
          rescue => e
            p e
            puts e.backtrace
            puts
          ensure
            client.destroy
          end
        end
      end

    end

    attr_reader :session,:commands,:character

    def initialize(session)
      @session = session
      @commands = Commands.new(self)
      self.class.register(self)
    end

    def destroy
      self.class.delete(self)
      @session.close
    end

    def message(text)
      @session.puts(text)
    end

    def login
      message "Name:"
      name = @session.gets.chomp

      destroy unless Character.exist?(name)
      @character = Character.load(name)
      
      message "Password:"
      destroy unless @character.password_matches?(@session.gets.chomp)
    end
  end
end
