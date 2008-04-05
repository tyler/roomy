class Mud
  class Client
    class MetaCommands
      class << self
        attr_reader :commands

        def command(name, options={}, &block)
          # Options: :for, :input

          @commands ||= {}
          @commands[name.to_s] = { :for => options[:for] || :all,
            :input => options[:input] || :split }

            define_method(name,block)
        end
      end

      def commands
        self.class.commands
      end
    end
  end
end

