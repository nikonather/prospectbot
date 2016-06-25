class BotController < ApplicationController
  require 'clearbit'
  include HTTParty

  def index

  end

  def oauth
    result = HTTParty.post(
      'https://slack.com/api/oauth.access',
      body: { client_id: ENV['SLACK_ID'], client_secret: ENV['SLACK_SECRET'], code: params[:code] }
    ).parsed_response
    if result['ok'] == true
      render text: "Bot added!"
    else
      render text: "Bot not added :("
    end
  end

  def command
    case params[:command]
    when "/prospect" #[role at company] [executive/director/manager] at [company domain]
      botquery = /(\w+)\s+(\w+)\s+at\s+([\w\.]+)/
      matched = botquery.match(params[:text])
      role = searchRole(matched[1])[:name]
      seniority = matched[2].downcase
      domain = matched[3].downcase#.gsub!('www.','').gsub!('http://','').gsub!('https://','')
      results = clearbitSearch(role: role, seniority: seniority, domain: domain)
      answer = "I found #{results.count} " + "prospect".pluralize(results.count) + ":"
      results.each do |result|
        answer += "\n#{result[:full_name]} #{result[:title]} #{result[:email]}"
      end
      payload = {
        text: answer
      }
      render json: payload

    end
  end

  def roles
    [
    {friendly_name:'CEO', name:'ceo', keywords:['ceo','chief executive officer']},
    {friendly_name:'Human Resources', name:'human_resources', keywords:['hr','human resources']},
    {friendly_name:'Public Relations', name:'public_relations', keywords:['pr','public relations']}
    {friendly_name:'Communications', name:'communications', keywords:['communications']}
    {friendly_name:'Consulting', name:'consulting', keywords:['consulting']}
    {friendly_name:'Customer Service', name:'customer_service', keywords:['customer service']}
    {friendly_name:'Education', name:'education', keywords:['education']}
    {friendly_name:'Engineering', name:'engineering', keywords:['engineering']}
    {friendly_name:'Finance', name:'finance', keywords:['finance']}
    {friendly_name:'Founder', name:'founder', keywords:['founder','co-founder']}
    {friendly_name:'Health Professional', name:'health_professional', keywords:['health professional']}
    {friendly_name:'Information Technology', name:'information_technology', keywords:['it','information technology']}
    {friendly_name:'Legal', name:'legal', keywords:['legal']}
    {friendly_name:'Owner', name:'owner', keywords:['owner']}
    {friendly_name:'President', name:'president', keywords:['president']}
    {friendly_name:'Product', name:'product', keywords:['product']}
    {friendly_name:'Real Estate', name:'real_estate', keywords:['real estate']}
    {friendly_name:'Operations', name:'operations', keywords:['operations']}
    {friendly_name:'Recruiting', name:'recruiting', keywords:['recruiting']}
    {friendly_name:'Research', name:'research', keywords:['research']}
    {friendly_name:'Sales', name:'sales', keywords:['sales']}
    ]
  end

  def searchRole(keyword)
    roles.each do |role|
      return role if role[:keywords].include?(keyword.downcase)
    end
    nil
  end

  def clearbitSearch(role:,seniority:,domain:)
    Clearbit.key = ENV['CLEARBIT_KEY']
    peoples = Clearbit::Prospector.search(role: role, seniority: seniority, domain: domain, limit: 1)
    peoples.map { |people| {full_name: people.name.full_name, title: people.title, email: people.email} }
  end
end
