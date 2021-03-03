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

def get_bug_lead_time(connection) 

	customer_bugs = connection.get_all_issue_info("project=#{JiraHelpers::PROJECT_ID} AND issueType=bug AND #{JiraHelpers::CUSTOMER_FIELD} is not empty and created < -0d and created > -180d")
	
	ap customer_bugs
	
	bugs = customer_bugs.select{|b| !("Done".eql?(b[:status]) && !"Fixed".eql?(b[:resolution]))}
	
	bugs.group_by{|i| i[:priority]}.map do |k, v|
	
		fixed = v.select{ |b| !b[:resolved_date].nil?}
	
		shipped = v.select{ |b| !b[:ship_date].nil? }
		fixed_not_shipped = v.select{ |b| b[:ship_date].nil? && !b[:resolved_date].nil?}
		not_fixed = v.select{ |b| b[:ship_date].nil? && b[:resolved_date].nil?}
		{
			priority: k,
			bug_count: v.size,
		
			total_fixed_count: fixed.size,
			fixed_avg_resolve_days: JiraHelpers.mean(fixed.map{ |b| b[:resolve_time_days]}),
		
			shipped: shipped.size,
			shipped_percent: JiraHelpers.percent(shipped.size, v.size),
			shipped_avg_lead_days: JiraHelpers.mean(shipped.map{ |b| b[:lead_time_days] }),
			shipped_avg_resolve_days: JiraHelpers.mean(shipped.map{ |b| b[:resolve_time_days] }),

			percent_shipped_within_thirty: JiraHelpers.percent(shipped.count{ |b| b[:lead_time_days]<30}, v.size),
			percent_shipped_within_sixty: JiraHelpers.percent(shipped.count{ |b| b[:lead_time_days]<60}, v.size),
			percent_shipped_within_ninety: JiraHelpers.percent(shipped.count{ |b| b[:lead_time_days]<90}, v.size),
		
			fixed_but_not_shipped: fixed_not_shipped.size,
			fixed_not_shipped_percent: JiraHelpers.percent(fixed_not_shipped.size, v.size),
		
			not_fixed: not_fixed.size,
			not_fixed_percent: JiraHelpers.percent(not_fixed.size, v.size),
		}
	end
end

connection = JiraConnection.new(ENV['JIRA_USERNAME'], ENV['JIRA_API_KEY'])
	
data = get_bug_lead_time(connection)
	
ap data, :index => false

column_names = data.first.keys
s=CSV.generate do |csv|
  csv << column_names
 data.each do |x|
    csv << x.values
  end
end

filename = "bugs-lead.csv"
File.write(filename, s)
