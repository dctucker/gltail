# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles logs from MySQL
class MysqlParser < Parser
	def parse( line )
		# 071013  9:43:17       7 Query       select * from users where username='test' limit 10

		if line.include? " Query"
			_, connection, query = /^.*\s+([0-9]+)\s+Query\s+(.+)$/.match(line).to_a
			@connection = connection

			if query
				_, shortquery = /^.* FROM\s+([^ ]+).*$/.match(query).to_a
				if @state[connection].class == NilClass
					@state[connection] = { }
				end

				if @state[connection][shortquery].class == NilClass
					@state[connection][shortquery] = 0
				end
				@state[connection][shortquery] += query.length

				add_activity(:block => 'sites', :name => server.name, :type => 3)
				add_activity(:block => 'database', :name => shortquery, :type => 3)
			end

		elsif line.include? " FROM " or line.include? " from "
			_, table = /^.* FROM ([^ ]+).*$/i.match(line).to_a
			if table
				@state[@connection][shortquery] += line.length
				add_activity(:block => 'database', :name => table, :type => 3)
			end

		elsif line.include? " Connect	"
			#                      8 Connect     debian-sys-maint@localhost on
			_, connection, user = /^.*\s+([0-9]+) Connect\s+(.+) on\s+/.match(line).to_a
			if user
				@connection = connection
				@state[connection] = { }
				add_activity(:block => 'logins', :name => "#{user}" )
				#add_event(:block => 'info', :name => "Database", :message => connection, :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0])
			end
		elsif line.include? " Quit"
			_, connection = /^.*\s+([0-9]+) Quit\s+$/.match(line).to_a
			if connection
				#add_event(:block => 'info', :name => "Database", :message => connection, :update_stats => true, :color => [1.5, 0.5, 0.5, 1.0])
				@state[connection].each_pair do |key, value|
					add_activity(:block => 'database', :name => key, :size => value * 100)
				end
				@state.delete connection
			end
		end
	end

	def initialize(source)
		super(source)
		@state = { }
		@connection = 0
	end
end
