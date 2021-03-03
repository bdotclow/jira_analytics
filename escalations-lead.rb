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

def get_ship_info(bugs) 

	fixed = bugs.select{ |b| !b[:resolved_date].nil?}
	not_fixed = bugs.select{ |b| b[:ship_date].nil? && b[:resolved_date].nil?}
	{
		bug_count: bugs.size,
	
		fixed_count: fixed.size,
		fixed_percent: JiraHelpers.percent(fixed.size, bugs.size),
		fixed_avg_resolve_days: JiraHelpers.mean(fixed.map{ |b| b[:resolve_time_days]}),

		not_fixed_count: not_fixed.size,
		not_fixed_percent: JiraHelpers.percent(not_fixed.size, bugs.size),
		not_fixed_avg_age_days: JiraHelpers.mean(not_fixed.map{ |b| b[:age_days]}),
	}
	
end


def get_bug_lead_time(connection) 

	escalations = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issueType=Escalation and created < -30d and created > -120d")

	get_ship_info(escalations)
	
	#customer_bugs.group_by{|i| i[:priority]}.map do |k, v|
	#	result = {:priority => k}
	#	result.merge get_ship_info(v)
	#end
end

connection = JiraConnection.new(ENV['JIRA_USERNAME'], ENV['JIRA_API_KEY'])
	
data = get_bug_lead_time(connection)
	
ap data, :index => false

#column_names = data.first.keys
column_names = data.keys
s=CSV.generate do |csv|
  csv << column_names
# data.each do |x|
#    csv << x.values
#  end
end

filename = "escalations-lead.csv"
File.write(filename, s)
