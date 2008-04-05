class Mud
  class Room
    class << self
      def rooms
        Area.areas.map{|a| a.rooms}.flatten
      end

      def create(args)
        raise(ArgumentError, "ID is required to create new room.  Use Area#create_room") unless args[:id]
        area = args.delete(:area)
        room = self.new(args)
        area.rooms << room

        room
      end

      def find(id)
        area = Area.areas.find{|area| id >= area.room_start && id <= area.room_end}
        area.rooms.find{|room| room.id == id}
      end
    end

    attr_accessor :id, :name, :description, :north, :east, :south, :west, :up, :down

    def initialize(args={})
      @id = args[:id]
      @name = args[:name]
      @description = args[:description]
      @north = args[:north]
      @east = args[:east]
      @south = args[:south]
      @west = args[:west]
      @up = args[:up]
      @down = args[:down]
    end

    def index
      area.rooms.index(self)
    end

    def area
      Area.areas.find{|area| id >= area.room_start && id <= area.room_end}
    end

    def characters
      Character.characters.to_a.inject([]){|out,c| out << c.last if c.last.room_id == @id; out}
    end
    
    %w(north east south west up down).each do |dir|
      define_method("room_#{dir}"){ Room.find( send(dir) ) }
    end

  end
end

