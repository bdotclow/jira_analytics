require 'httparty'
require 'json'
require 'amazing_print'
require 'byebug'
require 'time_difference'

require_relative 'JiraConnection'
require_relative 'JiraHelpers'

def get_resolution_stats(issue_info) 
	fixed = issue_info.select{ |i| "Fixed".eql?(i[:resolution])}.size
	
	change_in = Hash[issue_info.group_by{|i| i[:change_in]}.map{|k,v| [k,v.size]}]
	change_in.default = 0
	
	root_cause_counts = Hash[issue_info.group_by{|i| i[:root_cause]}.map{|k,v| [k,v.size]}]
	root_cause_counts.default = 0

	released_counts = Hash[issue_info.group_by{|i| i[:released]}.map{|k,v| [k,v.size]}]
	released_counts.default = 0		

	changes_involving_ui = change_in["UI Only"] + change_in["UI and Back End"]
	changes_back_end_only = change_in["Back End Only"]
	
	dev_broke = root_cause_counts["Introduced by story development"] + root_cause_counts["Introduced by bug fix"]
	never_worked = root_cause_counts["Never Worked"]
	
	released = released_counts["Yes (customer might be using it)"]
	unreleased = released_counts["No (no customer could be using it)"]

 	{	
 		change_ui: change_in["UI Only"],
 		change_back: change_in["Back End Only"],
 		change_both: change_in["UI and Back End"],
 		change_doc: change_in["Doc"],
 		change_build: change_in["Build System"],
 		ui_bug_percent: JiraHelpers.percent(changes_involving_ui, changes_involving_ui + changes_back_end_only),
 		
 		root_story: root_cause_counts["Introduced by story development"],
		root_bug: root_cause_counts["Introduced by bug fix"],
		root_never_worked: root_cause_counts["Never Worked"],
		root_usability: root_cause_counts["Usability (it *worked*, but was awkward to use)"],
		root_visual_glitch: root_cause_counts["Visual Glitch (spacing, small CSS issue, stuff doesn't fit, etc)"],
		root_requirements_changed: root_cause_counts["Requirements Changed"],
		root_third_party: root_cause_counts["3rd Party System Changed"],
		root_maintenance: root_cause_counts["Regular Maintenance"],
		root_scalability: root_cause_counts["Scalability Issue"],
		dev_broke_percent: JiraHelpers.percent(dev_broke, fixed),
		never_worked_percent: JiraHelpers.percent(root_cause_counts["Never Worked"], fixed),
 		other_percent: JiraHelpers.percent( fixed-dev_broke-never_worked, fixed),
 		
 		released: released,
 		unreleased: unreleased,
 		released_percent: JiraHelpers.percent(released, released+unreleased),
 		unreleased_percent: JiraHelpers.percent(unreleased, released+unreleased),
 	}
end

def get_stats_closed(connection)
	filter = "Commander Bugs - Closed in Last Week"
	issue_info = connection.get_all_filter_issue_info(filter)	
	
	base = JiraHelpers.get_base_stats(filter, issue_info)
	base.merge( get_resolution_stats(issue_info) )
end

connection = JiraConnection.new(JiraHelpers.get_username(), JiraHelpers.get_api_key())
	
data = get_stats_closed(connection)
	
ap data, :index => false

column_names = data.keys
s=CSV.generate do |csv|
  csv << column_names
  csv << data.values
end

filename = "lastweek-bugs-closed.csv"
File.write(filename, s)
