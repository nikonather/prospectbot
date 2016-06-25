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
      domain = matched[3].downcase.gsub!('www.','').gsub!('http://','').gsub!('https://','')
      results = searchClearbit(role: role, seniority: seniority, domain: domain)
      answer += "I found #{results.count} " + "prospect".pluralize(results.count) + ":"
      results.each do |result|
        answer += "\n#{result[:full_name]}, {result[:title]}, {result[:email]}"
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
    ]
  end

  def searchRole(keyword)
    roles.each do |role|
      return role if role[:keywords].include?(keyword.downcase)
    end
    nil
  end
  def clearbitSearch(role:,seniority:,domain:)
    peoples = Clearbit::Prospector.search(role: role, seniority: seniority, domain: domain, limit: 1)
    peoples.map { |people| {full_name: people.name.full_name, title: people.title, email: people.email} }
  end
end
