[
	'open-uri',
	'nokogiri',
	'open_uri_redirections'
].each{|g|
	require g
}

contribFile = ARGV[0]
expFile = ARGV[1]

File.open(contribFile,'w'){|f|
	headerArray = [
		"Committee ID",
		"Committee",
		"Expense date",
		"Contributor",
		"Contributor address",
		"Contributor city",
		"Contributor state",
		"Contributor zip code",
		"Contributor title",
		"Contributor type",
		"Contribution type",
		"Contribution amount"
	]
	f.puts(headerArray.join("\t"))
}

File.open(expFile,'w'){|f|
	headerArray = [
		"Committee ID",
		"Committee",
		"Expense date",
		"Expense name",
		"Expense address",
		"Expense city",
		"Expense state",
		"Expense zip code",
		"Expense amount",
		"Expense type",
		"Expense purpose"
	]
	f.puts(headerArray.join("\t"))
}

base_url = 'http://www.pbcelections.org/'
cmte_list_url = 'CFCommittees.aspx'

puts "OPENING "+base_url+cmte_list_url
cmte_list_pg = Nokogiri::HTML(open(base_url+cmte_list_url, :allow_redirections => :safe))
cmte_list_pg.css('ul')[-1].css('li a').each{|a|
	cmte_id = a['href'].split('=')[-1]
	cmte_name = a.text

	puts "OPENING "+base_url+a["href"]
	cmte_pg = Nokogiri::HTML(open(base_url+a['href'], :allow_redirections => :safe))
	cmte_pg.css('table td a').each{|a2|
		puts "OPENING "+base_url+a2["href"]
		report_pg = Nokogiri::HTML(open(base_url+a2['href'], :allow_redirections => :safe))
		report_pg.css('#ReportsList a').each{|a3|
			file_id = a3['href'].split('=')[1]
			contrib_url = base_url+'/CFFilingDetail.aspx?type=contribution&file_id='+file_id
			exp_url = base_url+'/CFFilingDetail.aspx?type=expenditure&file_id='+file_id

			puts "OPENING " +contrib_url
			contrib_page = Nokogiri::HTML(open(contrib_url, :allow_redirections => :safe))
			contrib_page.css('#pnlContributions tr')[1..-1].each{|contrib_tr|
				contrib_td = contrib_tr.css('td')
				contrib_date_str = contrib_td[0].text # DATAPOINT!!

				# contrib_date = Date.parse(contrib_date_str).to_s # DATAPOINT!! SQL-formatted date
				contributor_arr = contrib_td[1].to_s
					.gsub(/\<.*td.*\>|\t/,"")
					.gsub(/\n/," ")
					.split('<br>')
					.map{|item| 
						item.strip.gsub(/\<.*?\>/,"")
					}
				city_state_zip_arr = contributor_arr[2].split(',')

				begin
					contrib_name = contributor_arr[0] # DATAPOINT!!
					contrib_address = contributor_arr[1] # DATAPOINT!!
					contrib_city = city_state_zip_arr[0] # DATAPOINT!!
					contrib_state = city_state_zip_arr[1].strip[0..1] # DATAPOINT!!
					contrib_zip = city_state_zip_arr[1][-5..-1] # DATAPOINT!!
					contrib_title = contributor_arr.length===4 ? contributor_arr[3] : nil # DATAPOINT!!

					contributor_type = contrib_td[2].text # DATAPOINT!!
					contribution_type = contrib_td[3].text # DATAPOINT!!
					contrib_amt = contrib_td[4].text.gsub('$','').to_f # DATAPOINT!!					
				rescue Exception => e
					puts contrib_url+" GIVING US PROBLEMS"
					puts contributor_arr,city_state_zip_arr
					puts e,e.backtrace
				end

				rowData = [
					cmte_id,
					cmte_name,
					contrib_date_str,
					contrib_name,
					contrib_address,
					contrib_city,
					contrib_state,
					contrib_zip,
					contrib_title,
					contributor_type,
					contribution_type,
					contrib_amt
				]
				# p rowData
				File.open(contribFile,'a'){|f|
					f.puts(rowData.join("\t"))
				}
			} # DONE: contrib_page.css('#pnlContributions tr')[1..-1].each

			puts "OPENING "+exp_url
			exp_page = Nokogiri::HTML(open(exp_url, :allow_redirections => :safe))
			exp_page.css("#pnlExpenditures tr")[1..-1].each{|exp_tr|
				exp_td = exp_tr.css('td')
				exp_date_str = exp_td[0].text # DATAPOINT!!

				# exp_date = Date.parse(exp_date_str).to_s # DATAPOINT!!

				entity_arr = exp_td[1].to_s
					.gsub(/\<.*td.*\>|\t/,"")
					.gsub(/\n/," ")
					.split('<br>')
					.map{|item| 
						item.strip.gsub(/\<.*?\>/,"")
					}

				city_state_zip_arr = entity_arr[2].split(',')

				exp_name = entity_arr[0] # DATAPOINT!!
				exp_address = entity_arr[1] # DATAPOINT!!
				exp_city = city_state_zip_arr[0] # DATAPOINT!!
				exp_state = city_state_zip_arr[1].strip[0..1] # DATAPOINT!!
				exp_zip = city_state_zip_arr[1][-5..-1] # DATAPOINT!!

				exp_amt = exp_td[2].text.gsub('$','').to_f # DATAPOINT!!
				exp_type = exp_td[3].text # DATAPOINT!!
				exp_purpose = exp_td[4].text # DATAPOINT!!



				rowData = [
					cmte_id,
					cmte_name,
					exp_date_str,
					exp_name,
					exp_address,
					exp_city,
					exp_state,
					exp_zip,
					exp_amt,
					exp_type,
					exp_purpose
				]
				# p rowData
				File.open(expFile,'a'){|f|
					f.puts(rowData.join("\t"))
				}
			}
		}
	}
}

puts "DONE"