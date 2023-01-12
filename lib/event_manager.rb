require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end
# Clean and return a valid phone number string of 10 digits.
def clean_phone_numbers(num)
  num.gsub!(/[^0-9]/, '')
  # Replace bad phone numbers with this
  bad_num = '0000000000'
  len = num.length

  case len
  when len = 10 then num
  when (len = 11 && num[0] == 1) then num[0,9]
  else bad_num
  end
end

# Format phone numbers in the tradional formatting: "(XXX) XXX-XXXX"
def format_phone_number(num)
  '(' + num[0,3] + ') ' + num[3,3] + '-' + num[6,4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def most_common_value(array)
  array.group_by { |x| x }.max_by { |_key, group| group.size }[0]
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
popular_hours = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_num = clean_phone_numbers(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  # Creating time object from CSV's date / time.
  formatted_date_time = DateTime.strptime(row[:regdate], '%m/%d/%Y %H:%M')
  popular_hours << formatted_date_time.hour


  

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts "Bossman! The most popular hour is: " + most_common_value(popular_hours).to_s + "00."