module JiraHelpers
	extend self

	PROJECT_ID = 10094
	CUSTOMER_FIELD = 'cf[10139]'	# Field that tracks customer names(s)

	def get_base_stats(filter, issue_info)
		resolutions = Hash[issue_info.group_by{|i| i[:resolution]}.map{|k,v| [k,v.size]}]
		resolutions.default = 0
	
		fixed = resolutions["Fixed"]
		will_not_fix = resolutions["Won't Do"]
		unresolved = resolutions[nil]
	
		{
			filter: filter,
			count: issue_info.size,
		
			source_customer: issue_info.select{ |i| ! i[:customer].nil? }.size,
			source_epic: issue_info.select{ |i| ! i[:epicLink].nil? }.size,
			source_automation: issue_info.select{ |i| ! i[:automation].nil? }.size,
		
			resolution_unresolved: unresolved,
			resolution_fixed: fixed,
			resolution_wontfix: will_not_fix,
			resolution_other: issue_info.size - (fixed + will_not_fix + unresolved),
		}
	end
	
	
	def percent(num, den) 
		(num * 100 / den.to_f).round(2)
	end

	def mean(array)
	  (array.inject(0) { |sum, x| sum += x } / array.size.to_f).round(2)
	end


end