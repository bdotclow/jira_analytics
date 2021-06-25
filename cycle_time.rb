require 'httparty'
require 'json'
require 'amazing_print'
require 'byebug'
require 'time_difference'

require_relative 'JiraConnection'
require_relative 'JiraHelpers'

def get_ship_info(bugs) 

	fixed = bugs.select{ |b| !b[:resolved_date].nil?}
	not_fixed = bugs.select{ |b| b[:ship_date].nil? && b[:resolved_date].nil?}
	
	{
		bug_count: bugs.size,
	
		fixed_avg_lead_days: JiraHelpers.mean(fixed.map{ |b| b[:resolve_time_days]}),
		
		fixed_avg_cycle_time_days: JiraHelpers.mean(fixed.filter{ |b| !b[:cycle_time_days].nil? }.map{ |b| b[:cycle_time_days]}),
		fixed_max_cycle_time_days: fixed.filter{ |b| !b[:cycle_time_days].nil? }.map{ |b| b[:cycle_time_days]}.max,
		fixed_min_cycle_time_days: fixed.filter{ |b| !b[:cycle_time_days].nil? }.map{ |b| b[:cycle_time_days]}.min,
	}
	
end


def get_bug_lead_time(connection) 

	epics = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issueType=Epic and resolutiondate < 0d and resolutiondate > -90d")
	epic_info =  get_ship_info(epics)
	
	epics = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issueType=Story and resolutiondate < 0d and resolutiondate > -90d")
	story_info = get_ship_info(epics)
	
	epics = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issueType=Bug and resolutiondate < 0d and resolutiondate > -90d")
	bug_info =  get_ship_info(epics)
	
	{ 
		epic_info: epic_info,
		story_info: story_info,
		bug_info: bug_info
	}
end

connection = JiraConnection.new(JiraHelpers.get_username(), JiraHelpers.get_api_key())
	
data = get_bug_lead_time(connection)
	
ap data, :index => false
