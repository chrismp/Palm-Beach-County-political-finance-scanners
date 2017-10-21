[
	'open-uri',
	'nokogiri'
].each{|g|
	require g
}

contribFile = ARGV[0]
expFile = ARGV[1]

File.open(contribFile,'w'){|f|
	headerArray = [
		"Candidate ID",
		"Candidate name",
		"Election ID",
		"Election name",
		"Election date unformatted",
		"Election date formatted",
		"Office",
		"Contribution date unformatted",
		"Contribution date formatted",
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
		"Candidate ID",
		"Candidate name",
		"Election ID",
		"Election name",
		"Election date unformatted",
		"Election date formatted",
		"Office",
		"Expense date unformatted",
		"Expense date formatted",
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
cand_list_url = 'CFCandidates.aspx'

page = Nokogiri::HTML(open(base_url+cand_list_url))
page.css("#form1 td a").each{|a| 
	cand_url = base_url+a['href']

	cand_id = cand_url.split('=')[-1] # DATAPOINT!!
	cand_name = a.text # DATAPOINT!!

	cand_page = Nokogiri::HTML(open(cand_url))
	cand_page.css('#CFCandidateElections tr')[1..-1].each{|tr|
		td = tr.css('td')
		elex_id = td[1].css('a')[0]['href'].match(/elect_id\=.*?(?=\&)/).to_s.gsub('elect_id=','') # DATAPOINT!!
		elex_date_str = td[0].text # DATAPOINT!!
		elex_date = Date.parse(elex_date_str).to_s # DATAPOINT!!
		elex_name = td[1].text # DATAPOINT!!
		elex_ofc = td[2].text # DATAPOINT!!

		fin_report_summary_url = base_url+td[1].css('a')[0]['href']
		fin_report_summary_page = Nokogiri::HTML(open(fin_report_summary_url))
		fin_report_summary_page.css("#ReportsList a").each{|fin_detail_a| 
			fin_detail_url = base_url+fin_detail_a['href']
			file_id = fin_detail_url.split('=')[-1]
			
			contrib_url = base_url+'/CFFilingDetail.aspx?type=contribution&file_id='+file_id
			exp_url = base_url+'/CFFilingDetail.aspx?type=expenditure&file_id='+file_id

			contrib_page = Nokogiri::HTML(open(contrib_url))
			contrib_page.css('#pnlContributions tr')[1..-1].each{|contrib_tr|
				contrib_td = contrib_tr.css('td')
				contrib_date_str = contrib_td[0].text # DATAPOINT!!

				contrib_date = Date.parse(contrib_date_str).to_s # DATAPOINT!! SQL-formatted date
				contributor_arr = contrib_td[1].to_s
					.gsub(/\<.*td.*\>|\t/,"")
					.gsub(/\n/," ")
					.split('<br>')
					.map{|item| 
						item.strip.gsub(/\<.*?\>/,"")
					}
				city_state_zip_arr = contributor_arr[2].split(',')

				contrib_name = contributor_arr[0] # DATAPOINT!!
				contrib_address = contributor_arr[1] # DATAPOINT!!
				contrib_city = city_state_zip_arr[0] # DATAPOINT!!
				contrib_state = city_state_zip_arr[1].strip[0..1] # DATAPOINT!!
				contrib_zip = city_state_zip_arr[1][-5..-1] # DATAPOINT!!
				contrib_title = contributor_arr.length===4 ? contributor_arr[3] : nil # DATAPOINT!!

				contributor_type = contrib_td[2].text # DATAPOINT!!
				contribution_type = contrib_td[3].text # DATAPOINT!!
				contrib_amt = contrib_td[4].text.gsub('$','').to_f # DATAPOINT!!

				rowData = [
					cand_id,
					cand_name,
					elex_id,
					elex_name,
					elex_date_str,
					elex_date,
					elex_ofc,
					contrib_date_str,
					contrib_date,
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
				p rowData
				File.open(contribFile,'a'){|f|
					f.puts(rowData.join("\t"))
				}
			} # DONE: contrib_page.css('#pnlContributions tr')[1..-1].each

			exp_page = Nokogiri::HTML(open(exp_url))
			exp_page.css("#pnlExpenditures tr")[1..-1].each{|exp_tr|
				exp_td = exp_tr.css('td')
				exp_date_str = exp_td[0].text # DATAPOINT!!

				exp_date = Date.parse(exp_date_str).to_s # DATAPOINT!!

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
					cand_id,
					cand_name,
					elex_id,
					elex_name,
					elex_date_str,
					elex_date,
					elex_ofc,
					exp_date_str,
					exp_date,
					exp_name,
					exp_address,
					exp_city,
					exp_state,
					exp_zip,
					exp_amt,
					exp_type,
					exp_purpose
				]
				p rowData
				File.open(expFile,'a'){|f|
					f.puts(rowData.join("\t"))
				}
			} # DONE: exp_page.css("#{}pnlExpenditures tr")[1..-1].each
		} # DONE: fin_report_summary_page.css("#ReportsList a").each
	} # DONE: cand_page.css('#CFCandidateElections tr')[1..-1].each
	p '===='
} # DONE: page.css("#form1 td a").each