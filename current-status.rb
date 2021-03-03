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

def get_current_status(connection)
	escalations = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issuetype=Escalation AND resolution=Unresolved")
	created = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issuetype=Escalation AND created >= -1w")
	resolved = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issuetype=Escalation AND resolutiondate >= -1w")
	
		# Commander Customer Bugs - Open
	customer_bugs = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issuetype=Bug AND statusCategory != Done AND #{JiraHelpers::CUSTOMER_FIELD} is not EMPTY")
	
		# Commander Bugs - Gated
	gated_bugs = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issuetype=Bug AND resolution=Unresolved AND fixVersion is not EMPTY AND fixVersion != \"Non Commander\" AND \"Epic Link\" is EMPTY")
	
	wip_initiatives = connection.get_all_filter_issue_info("Commander Initiatives - In Progress")
	wip_epics = connection.get_all_filter_issue_info("Commander Epics - In Progress")
	wip_stories = connection.get_all_filter_issue_info("Commander Stories - In Progress")
	
	wip_all = connection.get_all_filter_issue_info("Commander - (All) In Progress")
	{
		escalation_created: created.size,
		resolved: resolved.size,
		escalation_count: escalations.size,
		
		bugs_customer: customer_bugs.size,
		bugs_gated: gated_bugs.size,
		bugs_in_progress: gated_bugs.select{ |i| "In Progress".eql?(i[:status_category])}.size,
		bugs_ready_for_qa: gated_bugs.select{ |i| "Ready for Test".eql?(i[:status])}.size,
		
		wip_initiatives: wip_initiatives.size,
		wip_epics: wip_epics.size,
		wip_stories: wip_stories.size,
		
		story_ready_for_test: wip_stories.select{ |i| "Ready for Test".eql?(i[:status])}.size,
		story_in_test: wip_stories.select{ |i| "In Test".eql?(i[:status])}.size,
		story_in_dev: wip_stories.select{ |i| "In Development".eql?(i[:status])}.size,
		
		wip_all: wip_all.size,
	}
end

connection = JiraConnection.new(ENV['JIRA_USERNAME'], ENV['JIRA_API_KEY'])
	
data = get_current_status(connection)
	
ap data, :index => false

column_names = data.keys
s=CSV.generate do |csv|
  csv << column_names
  csv << data.values
end

filename = "currentstatus.csv"
File.write(filename, s)
