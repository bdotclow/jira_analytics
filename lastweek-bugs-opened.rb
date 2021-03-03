require 'httparty'
require 'json'
require 'amazing_print'
require 'byebug'
require 'time_difference'

require_relative 'JiraConnection'
require_relative 'JiraHelpers'

#Provide username/jira key:
#"export JIRA_USERNAME=zzzz"
#"export JIRA_API_KEY=zzzz"

def get_stats_open(connection)
	filter = "Commander Bugs - Opened in Last Week"
	issue_info = connection.get_all_filter_issue_info(filter)
	
	JiraHelpers.get_base_stats(filter, issue_info)
end

connection = JiraConnection.new(ENV['JIRA_USERNAME'], ENV['JIRA_API_KEY'])
	
data = get_stats_open(connection)
	
ap data, :index => false

column_names = data.keys
s=CSV.generate do |csv|
  csv << column_names
  csv << data.values
end

filename = "lastweek-bugs-opened.csv"
File.write(filename, s)
