class Heroku::Command::Apps
  def upgrade
    unless tier = shift_argument
      raise(Heroku::Command::CommandFailed, "Usage: heroku apps:upgrade [tier]")
    end

    heroku.put("/apps/#{app}", :app => { :tier => tier })
    display "App updated to #{tier}"
  end

  alias_command "apps:upgrade", "apps:downgrade"
  
  def info
    validate_arguments!
    app_data = api.get_app(app).body

    unless options[:shell]
      styled_header(app_data["name"])
    end

    addons_data = api.get_addons(app).body.map {|addon| addon['name']}.sort
    collaborators_data = api.get_collaborators(app).body.map {|collaborator| collaborator["email"]}.sort
    collaborators_data.reject! {|email| email == app_data["owner_email"]}

    if options[:shell]
      if app_data['domain_name']
        app_data['domain_name'] = app_data['domain_name']['domain']
      end
      unless addons_data.empty?
        app_data['addons'] = addons_data.join(',')
      end
      unless collaborators_data.empty?
        app_data['collaborators'] = collaborators_data.join(',')
      end
      app_data.keys.sort_by { |a| a.to_s }.each do |key|
        hputs("#{key}=#{app_data[key]}")
      end
    else
      data = {}

      unless addons_data.empty?
        data["Addons"] = addons_data
      end

      data["Collaborators"] = collaborators_data

      if app_data["create_status"] && app_data["create_status"] != "complete"
        data["Create Status"] = app_data["create_status"]
      end

      if app_data["cron_finished_at"]
        data["Cron Finished At"] = format_date(app_data["cron_finished_at"])
      end

      if app_data["cron_next_run"]
        data["Cron Next Run"] = format_date(app_data["cron_next_run"])
      end

      if app_data["database_size"]
        data["Database Size"] = format_bytes(app_data["database_size"])
      end

      data["Git URL"] = app_data["git_url"]

      if app_data["database_tables"]
        data["Database Size"].gsub!('(empty)', '0K') + " in #{quantify("table", app_data["database_tables"])}"
      end

      if app_data["dyno_hours"].is_a?(Hash)
        data["Dyno Hours"] = app_data["dyno_hours"].keys.map do |type|
          "%s - %0.2f dyno-hours" % [ type.to_s.capitalize, app_data["dyno_hours"][type] ]
        end
      end

      data["Owner Email"] = app_data["owner_email"]

      if app_data["repo_size"]
        data["Repo Size"] = format_bytes(app_data["repo_size"])
      end

      if app_data["slug_size"]
        data["Slug Size"] = format_bytes(app_data["slug_size"])
      end

      data["Stack"] = app_data["stack"]
      if data["Stack"] != "cedar"
        data.merge!("Dynos" => app_data["dynos"], "Workers" => app_data["workers"])
      end

      data["Web URL"] = app_data["web_url"]
      data["Tier"] = app_data["tier"].capitalize if app_data["tier"]

      styled_hash(data)
    end
  end
end
