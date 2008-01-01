#!/usr/bin/env ruby
# Copyright (C) 2006 Mauricio Fernandez <mfp@acm.org> http://eigenclass.org
# Use and distribution under the same terms as Ruby.
#
# Use as in
#   ruby compose.rb main.rb somelib.rb anotherlib.rb=foo.rb > new-main.rb
# anotherlib.rb will be renamed to foo.rb in the DataFS

module DataFS
  require 'yaml'
  require 'stringio'

  FStat = Struct.new(:name, :size, :offset)

  class Writer
    def initialize
      @files = {}
    end

    def add(filename, contents)
      @files[filename] = contents
    end

    def dump(anIO = nil)
      unless anIO
        ret_content = true
        anIO = StringIO.new("")
      end
      offset = 0
      index = {}
      @files.keys.sort.each do |name|
        contents = @files[name]
        index[name] = FStat.new(name, contents.size, offset)
        offset += contents.size
      end
      serialized_index = YAML.dump(index)
      anIO.puts(serialized_index.size)
      anIO.write(serialized_index)
      @files.keys.sort.each{|name| anIO.write(@files[name]) }

      if ret_content
        anIO.string
      else
        anIO
      end
    end
  end
  
  class Reader
    def initialize(io)
      @io = io
      idx_size = @io.gets
      @index = YAML.load(@io.read(idx_size.to_i))
      @initial_pos = io.pos
    end

    def fstat(filename)
      @index[filename]
    end

    def open(filename)
      raise Errno::ENOENT unless fstat = @index[filename]
      file_entry = FileStream.new(@io, @initial_pos + fstat.offset, fstat.size)
      if block_given?
        yield file_entry
      else
        return file_entry
      end
    end

    class FileStream
      def initialize(io, offset, size)
        @io = io.dup
        @offset = offset
        @size = size
        @pos = 0
        rewind
      end

      def eof?; @pos == @size end
      def rewind
        @io.pos = @offset 
        @pos = 0 
      end

      def read(size = @size)
        ret = @io.read([@size - @pos, size].min)
        @pos += ret.size if ret
        ret
      end
    end
  end
end


main = ARGV.shift
unless main
  puts <<EOF
    ruby compose.rb <main.rb> <lib.rb>[=newname.rb] ...
EOF
  exit
end

datafs = DataFS::Writer.new
ARGV.each do |fname|
  src, dest = fname.split(/=/)
  dest ||= src
  datafs.add(dest, File.read(src))
end

puts File.read(main)
mydata = DataFS::Reader.new(DATA)
puts <<EOF
BEGIN { 
#{mydata.open("datafs.rb").read}
#{mydata.open("datafs_require.rb").read}
}
EOF
puts "__END__"
datafs.dump($stdout)

__END__
182
datafs.rb: !ruby/struct:DataFS::FStat 
  name: datafs.rb
  size: 1738
  offset: 0
datafs_require.rb: !ruby/struct:DataFS::FStat 
  name: datafs_require.rb
  size: 568
  offset: 1738

module DataFS
  require 'yaml'
  require 'stringio'

  FStat = Struct.new(:name, :size, :offset)

  class Writer
    def initialize
      @files = {}
    end

    def add(filename, contents)
      @files[filename] = contents
    end

    def dump(anIO = nil)
      unless anIO
        ret_content = true
        anIO = StringIO.new("")
      end
      offset = 0
      index = {}
      @files.keys.sort.each do |name|
        contents = @files[name]
        index[name] = FStat.new(name, contents.size, offset)
        offset += contents.size
      end
      serialized_index = YAML.dump(index)
      anIO.puts(serialized_index.size)
      anIO.write(serialized_index)
      @files.keys.sort.each{|name| anIO.write(@files[name]) }

      if ret_content
        anIO.string
      else
        anIO
      end
    end
  end
  
  class Reader
    def initialize(io)
      @io = io
      idx_size = @io.gets
      @index = YAML.load(@io.read(idx_size.to_i))
      @initial_pos = io.pos
    end

    def fstat(filename)
      @index[filename]
    end

    def open(filename)
      raise Errno::ENOENT unless fstat = @index[filename]
      file_entry = FileStream.new(@io, @initial_pos + fstat.offset, fstat.size)
      if block_given?
        yield file_entry
      else
        return file_entry
      end
    end

    class FileStream
      def initialize(io, offset, size)
        @io = io.dup
        @offset = offset
        @size = size
        @pos = 0
        rewind
      end

      def eof?; @pos == @size end
      def rewind
        @io.pos = @offset 
        @pos = 0 
      end

      def read(size = @size)
        ret = @io.read([@size - @pos, size].min)
        @pos += ret.size if ret
        ret
      end
    end
  end
end

module Kernel
  DATAFS = DataFS::Reader.new(DATA)
  alias_method :__pre_datafs_require, :require
  def require(name, *args, &b)
    if ["", ".rb"].include? File.extname(name)
      # very naïf, 1.9 issues, etc.
      return false if $".include?(name) || $".include?(name + ".rb")

      try_and_load = lambda do |n|
        DATAFS.fstat(n) and 
          (eval(DATAFS.open(n).read, TOPLEVEL_BINDING, n) || true) and $" << n
      end
      return true if try_and_load[name] || try_and_load[name + ".rb"]
    end

    __pre_datafs_require(name, *args, &b)
  end
end

