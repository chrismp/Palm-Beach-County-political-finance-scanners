[
	'rubygems',
	'open-uri',
	'nokogiri',
	'sequel'
].each{|g|
	require g
}

DB = Sequel.connect( 
	:adapter => 'mysql',
	:user=>ARGV[0], 
	:password=>ARGV[1], 
	:host=>ARGV[2],
	:database=>ARGV[3]
)

DB.create_table? :pbc_cand_contrib do
	primary_key :row_id
	Date :scan_date
	Integer :cand_id
	varchar :cand_name
	Integer :elex_id
	varchar :elex_name
	varchar :elex_date_str
	Date :elex_date
	varchar :elex_ofc
	varchar :contrib_date_str
	Date :contrib_date
	varchar :contrib_name
	varchar :contrib_address
	varchar :contrib_city
	varchar :contrib_state
	varchar :contrib_zip
	varchar :contrib_title
	varchar :contributor_type
	varchar :contribution_type
	Float :contrib_amt
end
pbc_cand_contrib = DB[:pbc_cand_contrib]

DB.create_table? :pbc_cand_exp do 
	primary_key :row_id
	Date :scan_date
	Integer :cand_id
	varchar :cand_name
	Integer :elex_id
	varchar :elex_name
	varchar :elex_date_str
	Date :elex_date
	varchar :elex_ofc
	varchar :exp_date_str
	Date :exp_date
	varchar :exp_name
	varchar :exp_address
	varchar :exp_city
	varchar :exp_state
	varchar :exp_zip
	Float :exp_amt
	varchar :exp_type
	varchar :exp_purpose
end
pbc_cand_exp = DB[:pbc_cand_exp]

now_str = (Time.now).to_s
# yesterday_time_str = (Time.now - 86400).to_s
today_str = Date.parse(now_str).to_s
# yesterday_str = Date.parse(yesterday_time_str).to_s

latest_scan_date_contrib = DB[
	"SELECT scan_date
	FROM pbc_cand_contrib
	ORDER BY scan_date DESC
	LIMIT 1;"
].map{|r| r[:scan_date]}[0]
latest_scan_date_contrib = latest_scan_date_contrib===nil ? Date.parse('1900-01-01') : latest_scan_date_contrib

latest_scan_date_exp = DB[
	"SELECT scan_date
	FROM pbc_cand_exp
	ORDER BY scan_date DESC
	LIMIT 1;"
].map{|r| r[:scan_date]}[0]
latest_scan_date_exp = latest_scan_date_exp===nil ? Date.parse('1900-01-01') : latest_scan_date_exp

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

				if(Date.parse(contrib_date_str) > latest_scan_date_contrib)
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

					pbc_cand_contrib.insert(
						:scan_date => today_str,
						:cand_id => cand_id,
						:cand_name => cand_name,
						:elex_id => elex_id,
						:elex_name => elex_name,
						:elex_date_str => elex_date_str,
						:elex_date => elex_date,
						:elex_ofc => elex_ofc,
						:contrib_date_str => contrib_date_str,
						:contrib_date => contrib_date,
						:contrib_name => contrib_name,
						:contrib_address => contrib_address,
						:contrib_city => contrib_city,
						:contrib_state => contrib_state,
						:contrib_zip => contrib_zip,
						:contrib_title => contrib_title,
						:contributor_type => contributor_type,
						:contribution_type => contribution_type,
						:contrib_amt => contrib_amt
					)

					p [
						today_str,
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
				else 
					p "CONTRIBUTION RECORD LIKELY IN DATABASE"
				end
			} # DONE: contrib_page.css('#pnlContributions tr')[1..-1].each

			exp_page = Nokogiri::HTML(open(exp_url))
			exp_page.css("#pnlExpenditures tr")[1..-1].each{|exp_tr|
				exp_td = exp_tr.css('td')
				exp_date_str = exp_td[0].text # DATAPOINT!!

				if(Date.parse(exp_date_str) > latest_scan_date_exp)
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

					pbc_cand_exp.insert(
						:scan_date => today_str,
						:cand_id => cand_id,
						:cand_name => cand_name,
						:elex_id => elex_id,
						:elex_name => elex_name,
						:elex_date_str => elex_date_str,
						:elex_date => elex_date,
						:elex_ofc => elex_ofc,
						:exp_date_str => exp_date_str,
						:exp_date => exp_date,
						:exp_name => exp_name,
						:exp_address => exp_address,
						:exp_city => exp_city,
						:exp_state => exp_state,
						:exp_zip => exp_zip,
						:exp_amt => exp_amt,
						:exp_type => exp_type,
						:exp_purpose => exp_purpose
					)

					p [
						today_str,
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
				else 
					p "EXPENDITURE RECORD LIKELY IN DATABASE"
				end
			} # DONE: exp_page.css("#{}pnlExpenditures tr")[1..-1].each
		} # DONE: fin_report_summary_page.css("#ReportsList a").each
	} # DONE: cand_page.css('#CFCandidateElections tr')[1..-1].each
	p '===='
} # DONE: page.css("#form1 td a").each