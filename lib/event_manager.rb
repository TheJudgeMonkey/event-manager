require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

hour_arr = Array.new
day_arr = Array.new
hour_hash = Hash.new(0)
day_hash = Hash.new(0)

def clean_phone_number(phone_number)
    phone_number.to_s.gsub!(/[\D]/, '')
    if phone_number.length == 10
        phone_number
    elsif phone_number.length == 11 && phone_number[0] == '1'
        phone_number = phone_number.slice(1..10)
    else 
        "Bad phone number"
    end
end

def get_hour(reg_date)
    reg_time = Time.strptime(reg_date, '%m/%d/%Y %k:%M').strftime('%k')
end

def get_day(reg_date)
    reg_time = Time.strptime(reg_date, '%m/%d/%Y %k:%M').strftime('%A')
end

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
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

puts 'EventManager initialized.'

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    phone_number = clean_phone_number(row[:homephone])
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id,form_letter)

    get_hour = get_hour(row[:regdate])
    get_day = get_day(row[:regdate])

    hour_arr.push(get_hour)
    day_arr.push(get_day)
end

best_hour = hour_arr.reduce(hour_hash) do |hour_hash, v|
    hour_hash[v] += 1
    hour_hash
end

best_day = day_arr.reduce(day_hash) do |day_hash, v|
    day_hash[v] += 1
    day_hash
end

puts best_hour.max_by{|hour_hash,v| v}[0]
puts best_day.max_by{|day_hash,v| v}[0]
