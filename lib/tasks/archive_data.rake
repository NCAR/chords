require 'task_helpers/cuahsi_helper'

namespace :archive do
  task send_data: :environment do |task, args|
    # Rails.logger.debug "send data called at " + Time.now.utc.to_s

    # Check to make sure archiving is enabled before sending data

    if Archive.first.enabled != true
      # Archiving is disabled, no data will be transmitted
      # puts "Archiving is disabled, no data will be transmitted"

      # exit the rake task
      next
    end

    # retrieve the current archive jobs data points to be sent
    jobs = ArchiveJob.where("status = 'scheduled'")

    profile = Profile.first
    sourceID = profile.get_cuahsi_sourceid(profile.domain_name)

    # loops through the jobs
    jobs.each do |job|
      success = true

      # retrieve the data points for the date range
      Instrument.find_each do |inst|
        points = GetTsPoints.call(TsPoint, "data", inst.id, job.start_at, job.end_at)


        # extract site, instrument and var information
        siteID = inst.site.get_cuahsi_siteid
        url = inst.instrument_url
        methodID = inst.get_cuahsi_methodid(url)

        points.each do |p|
          v = Var.find(p['var'])
          variableID = v.get_cuahsi_variableid(profile.domain_name + ":" + inst.site.id.to_s + ":" + inst.id.to_s + ":" + v.id.to_s)

          # build the data array
          data = Array.new
          data.push(p["time"])
          data.push(p["value"])


          # send the data array
          value = {
            "user" => Rails.application.config.x.archive['username'],
            "password" => Rails.application.config.x.archive['password'],
            "SiteID" => siteID,
            "VariableID" => variableID,
            "MethodID" => methodID,
            "SourceID" => sourceID,
            "values" => data
          }

          uri_path = Rails.application.config.x.archive['base_url'] + "/default/services/api/values"
          response = CuahsiHelper::send_request(uri_path, value)

          # retrieve any errors that occurred
          if (response.code.to_s != '200')
            success = false
            job.message += p["time"] + response.body.to_s + "\n"
          end
        end
      end
      # update status of the archive job
      if success
        job.status = 'success'
      else
        job.status = 'failed'
      end

      job.save

    end
  end
end
