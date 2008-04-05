require 'digest/sha1'

class Mud
  class Character
    class << self
      attr_reader :characters

      def load(name)
        name = name.downcase

        @characters ||= {}
        character = YAML::load_file(filename(name))
        @characters[name] = character
        character
      end

      def exist?(name)
        File.exist?(filename(name))
      end

      # need more defaults set here... things like initial room_id
      def create(name)
        name = name.downcase

        char = self.new(name)
        char.save

        @characters ||= {}
        @characters[name] = char

        char
      end

      def unload(name)
        name = name.downcase
        @characters.delete(name)
      end

      def filename(name)
        File.join(SAVE_DIR,"#{name.downcase}.yaml")
      end

    end

    SAVE_DIR = File.join(File.dirname(__FILE__), 'characters')

    attr_accessor :name, :area, :room_id
    attr_reader :password_hash

    def initialize(name)
      @name = name
    end

    def room
      Room.find(@room_id)
    end

    def client
      Client.clients.find{|c| c.character == self}
    end

    def save
      File.open(filename,"w"){|f| f << self.to_yaml }
    end

    def password=(password)
      @password_hash = Digest::SHA1.hexdigest(plain_text)
    end

    def password_matches?(password)
      Digest::SHA1.hexdigest(password) == @password_hash
    end

    def filename
      self.class.filename(@name)
    end

    # These models really need customer to_yaml methods... it sucks not being able to just throw instance
    # variables around when they're useful, for fear of screwing up the yamls
  end
end
