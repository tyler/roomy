class Mud
  class Area
    
    class << self
      attr_accessor :areas

      def load_all
        @areas = Dir["#{SAVE_DIR}/*"].map{|area| YAML::load_file(area) }.sort_by{|a| a.id}
      end

      def save_all
        @areas.each{|a| a.save}
      end

      def create(name)
        area = self.new(name)
        
        area.id = generate_id
        @areas << area
        area
      end

      def generate_id
        @areas.sort{|a,b| b.id <=> a.id}.first.id + 1
      end

      def find(id)
        @areas.find{|a| a.id == id}
      end
    end

    SAVE_DIR = File.join(File.dirname(__FILE__), 'areas')

    attr_accessor :rooms, :name, :id, :room_start, :room_end

    def initialize(name)
      @name = name
    end

    def create_room(args)
      args[:id] = generate_room_id
      args[:area] = self
      room = Room.create(args)

      room
    end

    def save
      File.open(filename,"w"){|f| f << self.to_yaml }
    end

    def filename
      File.join(SAVE_DIR, "#{@name}.yaml")
    end

    def generate_room_id
      room_ids = @rooms.map{|r| r.id}

      def gen(start,finish,room_ids)
        return nil if start > finish
        return room_ids.include?(start) ? gen(start+1,finish,room_ids) : start
      end

      gen(@room_start,@room_end,room_ids)
    end

  end
end
