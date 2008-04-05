class Mud
  class Client
    class Commands < Mud::Client::MetaCommands

      def initialize(client)
        # At some point, permissioning code will go here.
        # Perhaps simply setting some instance variable which is then used
        # to limit what commands, and what effects of commands, a client
        # can have.  Or perhaps by destroying methods completely, thus 
        # obliterating any potential security holes?
        # In fact, in the latter case, the creation of "MetaCommands"
        # class might be cool.  It could be used to create a DSL for the
        # creation of secure commands. Something like:
        #
        # command(:immortal) do
        #   blah.blah(:blah)
        # end
        #
        # Even more so, perhaps some commands want to have 
        #
        # or maybe...
        #
        # immortal(:command) do
        #   blah.blah
        # end
        #
        # but theres another thing that I hadn't thought about until just a bit ago
        # especially for builder commands, theres a lot of nested commands:
        # area create
        # area save
        # area info
        # area set
        #
        # so, rather than having big, ugly case statements all over the place, I think
        # a nested setup might be nice...
        #
        # namespace(:area) do
        #   command(:create) do |input|
        #     blah.blah
        #   end
        #
        #   command(:save) do |input|
        #     blah.save
        #   end
        #
        #   default do
        #     this.gets.called(:if_theres_no_secondary_command)
        #   end
        # end
        #
        # I came up with a better solution than all of the above.  Check out the ED comments in 
        # my "Metaprogramming Makes Me Happy" article.

        @client = client
      end

      def bad_command(input=nil)
        @client.message("Huh?  Quit making crap up.")
      end

      def find_command(command)
        key = commands.keys.grep(/^#{command}/).first
        return [key,commands[key]] if key
      end

      def dispatch(input)
        command = find_command( input.split(/\s+/).first )

        return bad_command(input) unless command
        args = (md = input.match(/\s+/)) ? md.post_match : ''
        args = args.split(' ') if command.last[:input] == :split

        self.send(command.first.to_sym,args)
      end

      # Helpers need to be factored out into a module or something
      def message(input)
        @client.message(input)
      end

      def message_room(input, options)
        chars = @client.character.room.characters
        chars.delete(@client.character) if options[:except] == :me

        chars.each{|c| c.client.message(input)}
      end

      def message_all(input)
        Client.message_all(input)
      end


      # The actual commands need to be factored out into a module or something
      
      command(:look) do |input|
        # need a helper for this, since its used often
        room = Room.find(@client.character.room_id)

        # this needs factored out
        directions = %w(north east south west up down).inject(""){|out,d| room.send(d).nil? ? out : out + d[0,1].upcase}

        # going to need template files of some kind, I believe... erb might work dandily
        message %Q{
#{room.name} (#{room.id})

#{room.description}

[#{directions}]
}
      end

      %w(north east south west up down).each do |dir|
        command(dir.to_sym) do |input|
          @client.character.room_id = @client.character.room.send(dir)
          # it would be nice to be able to call other commands without passing strings
          look('')
        end
      end

      command(:goto) do |input|
        @client.character.room_id = input[0].to_i
        look('')
      end

      command(:whoami) do |input|
        message "Your are #{@client.character.name}"
      end

      command(:gecho, :input => :whole) do |input|
        message_all input
      end

      command(:say, :input => :whole) do |input|
        # consider implementing templates where I can do something like...
        #
        # input.format(:template_name, :args => {})
        # ..or..
        # render(:template_name, :args => {})
        message_room("#{@client.character.name} says \"#{input}\"", :except => :me)
        message "You say \"#{input}\""
      end

      command(:room) do |input|
        case input[0]
        when "dig"
          # helperize this
          room = @client.character.room
          # I think the next two lines need to be factored out of here (controller, heh) and into the Room
          # class (model)... soomething like...
          # 
          # current_room.create_neighbor(:west, :name => "...")
          #
          # then, when connecting two rooms, as well...
          #
          # current_room.connect_neighbor(:west, 15)
          #
          # or maybe I want something more like...
          #
          # current_room.connect_west(15)

          new_room = room.area.create_room(:name => "New Room", :description => "New Room Description")
          room.send("#{input[1]}=", new_room.id)
          # need a way to reverse a direction... a guess a hash table and a global function would be fine...
        end
      end

      command(:area) do |input|
        # need to implement "info" as well, to display the current data
        case input[0]
        when "create"
          area = Area.create(input[1..-1].join(' '))
          area.save
          # I think maybe I want to create a room with the _room_start_ id
          # and maybe goto it?  Maybe not.  But I think creating the room 
          # would be good, as thats the first thing everyone will do anyway...
          # and if they weren't going to... it still doesn't cause any harm
          message "Created area: #{area.inspect}"
        when "list"
          # ugh... this reminds me... we're gonna need a permission structure, and to record who changes
          # what.  That sucks.  I don't want to do that.  Maybe I can get away with not doing it.
          message Area.areas.inject(""){|out,a| out + "#{a.id}. #{a.name} (#{a.room_start} to #{a.room_end})\n"}
        when "set"
          # Expects something like: area set 1 room_start=5 room_end=10


          area = Area.find(input[1].to_i)

          # This needs to be factored out completely.
          # something like this...
          #
          # area.update_attributes( hashify_arguments[2..-1] )
          input[2..-1].each do |term|
            md = term.match(/([^=\s]+)=([^=\s]+)/)

            value = case md[2]
                    when /^\d+$/
                      md[2].to_i
                    when '[]'
                      []
                    when '{}'
                      {}
                    else
                      md[2]
                    end

            area.send("#{md[1]}=", value)
          end

        when "save_all"
          Area.save_all
        # need a "area save 1" type subcommand as well
        else
          bad_command
        end
      end

      command(:character) do |input|
        case input[0]
        when "create"
          char = Character.create(input[1])
          message "Created character: #{char.inspect}"
        when "list"
          message Character.characters.values.inject(""){|out,c| out + "#{c.name}\n"}
        when "load"
          char = Character.load(input[1])
          message "Loaded '#{char.name}'"
        # need unload as well... needs to make sure the client connection gets destroyed
        # as well, if its an actual connected user being unloaded
        end
      end

      command(:quit) do |input|
        # oi... characters need to be saved more often than just on quit... figuring out how to handle that will be fun
        @client.character.save
        message "Thanks for logging on.  Shoot a rocket."
        @client.destroy
      end

    end
  end
end
