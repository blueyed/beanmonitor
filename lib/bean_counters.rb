#!/usr/bin/ruby

require 'yaml'

# Class used to parse and compare user_beancounters files created by
# OpenVZ
class BeanCounters
	attr_accessor :raw
	

	# Returns the entire parsed data for a given userid
	def [](value)
		return nil unless @data.has_key? value
		return @data[value]
	end


	# Returns whether or not any failcounters have changed between two objects.
	def ==(value)
		return (diff(value).size == 0)
	end


	# Compares the current BeanCounters object with another beancounters object given as 
	# the only argument. The method returns a hash of userids with another hash as their
	# respecitve value, listing all differing counters and the "amount of change" should
	# usually be a positive integer.
	# 
	# If between creating the two BeanCounter objects, a new user id has been created, 
	# no change is reported. This is to avoid mailing everyone whenever a new userid
	# is added or deleted. Cool beans, I know.
	def diff(obj)
		result = Hash.new

		@data.each do |uid,d|
			other = obj[uid]
			next if other.nil?

			d.each do |counter,values|
				dist = other[counter]['failcnt'] - values['failcnt']
				if dist != 0 then
					result[uid] = Hash.new unless result.has_key? uid
					result[uid][counter] = dist
				end
			end
		end

		return result
	end


  # Creates a new object by parsing the specified file. Fails with an error message if
  # the file can't be read. Unknown condition if specified file is not a user_beancounters
  # file.
  # TODO: add check for correct file format
	def initialize(file)
		begin
			@raw = File.read(file)
		rescue
			raise "Can't open file: %s" % $!
		end

		parse_array
	end


	private 
	  # Parses the raw beancounters file adding all data to the @data instance variable. 
	  # After this, @data contains a hash with all user ids as key and their respective
	  # counters a value. For each counter, another hash is supplied including all 
	  # limit types (held, maxheld...) as keys and their values as value.
  	def parse_array()
  		@data = Hash.new
  		header = nil
  		current_uid = nil
  		@raw.each do |line|
  			if line =~ /^Version/ then
  				# skip first line / version
  			else
  				line.gsub!(/^[\t\s]*/, '')
  				parts = line.split(/[\t\s]+/)

  				if parts[0] == "uid" then
  					# header line
  					header = parts[2..parts.size]
  				else
  					if parts[0] =~ /:$/ then
  						# new uid
  						current_uid = parts[0].gsub(/:$/, '').to_i
  						@data[current_uid] = Hash.new

  						# this seems like a bit .... complicated
  						for i in 1..(parts.size-1) do
  							parts[i-1] = parts[i]
  						end
  					end

  					@data[current_uid][parts[0]] = Hash.new
					
  					header.each_index do |index|
  						@data[current_uid][parts[0]][header[index]] = parts[1+index].to_i 
  					end
  				end
  			end
  		end
  	end
end