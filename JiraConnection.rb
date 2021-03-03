require 'httparty'
require 'json'
require 'amazing_print'
require 'byebug'
require 'time_difference'

PAGE_SIZE = 50

class JiraConnection 
	def initialize(user, key)
		@auth = {:username => user, :password => key}
	end

		# Get all issues for the specified JQL
	def get_all_issue_info(jql) 
		issues = get_all_issues(jql)

		get_issue_info(issues)
	end

		# Get all issues for the specified filter
	def get_all_filter_issue_info(filterName) 
		get_all_issue_info('filter = "'+filterName+'"')
	end
	
	def get_issue_info(issues) 			
		issues.map do |issue| 
			created = issue.dig('fields', 'created')

			fixVersions = issue.dig('fields', 'fixVersions')	
			if fixVersions.nil? 
				fix = nil
			elsif fixVersions.size==1
				fix = fixVersions[0]
			else
				fix = fixVersions.min_by {|fv| fv['releaseDate']}	
			end
	
			lead_time_days = nil
			shipped_on = nil
			fix_version = nil

			unless fix.nil? 
				fix_version = fix['name']
	
				if fix['released']
					shipped_on = fix['releaseDate']
					lead_time_days = TimeDifference.between(created, fix['releaseDate']).in_days	
				end
			end

			resolved = issue.dig('fields', 'resolutiondate')
			unless resolved.nil?
				resolve_time = TimeDifference.between(created, resolved).in_days	
			end
			{ 
				key: issue['key'],
				created: created,
				age_days: TimeDifference.between(created, DateTime.now).in_days,
				priority: issue.dig('fields', 'priority', 'name'),
		
				status: issue.dig('fields', 'status', 'name'),
				status_category: issue.dig('fields', 'status', 'statusCategory', 'name'),

					# Details about resolution, if resolved
				resolution: issue.dig('fields', 'resolution', 'name'),
				resolved_date: resolved,
				resolve_time_days: resolve_time,
		
					# Version it was (or will be) fixed in
				fix_version: fix_version,
		
					# If in shipped release, date of shipping and overall lead time
				ship_date: shipped_on,
				lead_time_days: lead_time_days,
   
					# Root cause analysis
				released: issue.dig('fields', 'customfield_10114', 'value'),
				root_cause: issue.dig('fields', 'customfield_10122', 'value'),
				change_in: issue.dig('fields', 'customfield_10117', 'value'),
   
					# Source (customer, epic, automation framework)
				customer: issue.dig('fields', 'customfield_10139')&.join(","),
				epicLink: issue.dig('fields', 'customfield_10013'), 
				automation: issue.dig('fields', 'customfield_10113', 'value'),
			}
		end
	end

	def log_issues(issues) 
		issues.each do |issue|
			puts "#{issue[:key]}"
			puts "\tCustomer: #{issue[:customer]}" unless issue[:customer].nil?
	
			issue[:resolution].nil? ? (puts "\tUNRESOLVED") : (puts "\tResolution: #{issue[:resolution]}")
	
			if "Fixed".eql?(issue[:resolution]) then
				puts "\tReleased: #{issue[:released]}"
				puts "\tChange In: #{issue[:change_in]}"
				puts "\tRoot Cause: #{issue[:root_cause]}"
			end
	
			puts "\tEpic: #{issue[:epicLink]}" unless issue[:epicLink].nil?
			puts "\tAutomation: #{issue[:automation]}" unless issue[:automation].nil?
		end
	end

	def get_issues(jql, start) 
			# limiting the fields makes it much quicker
		fields = 'fixVersions, created, resolutiondate, priority, key, customfield_10139, status, resolution, customfield_10114, customfield_10122, customfield_10117, customfield_10013, customfield_10113'
		parameters = {'jql' => jql, 'startAt' => start, 'fields' => fields, 'maxResults' => PAGE_SIZE}#, 'fields' => '*all'}
		response = HTTParty.get('https://snowsoftware.atlassian.net/rest/api/3/search', :query => parameters, :basic_auth => @auth)
		response.parsed_response
	end

	def get_all_issues(jql) 
		start = 0
		issues = []
		loop do
			response = get_issues(jql, start)
			issues.concat response['issues']

			start = start + PAGE_SIZE
 
			break if response['issues'].size < PAGE_SIZE
		end

		issues
	end
end	
