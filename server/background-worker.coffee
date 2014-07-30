#!/usr/bin/env coffee
require('coffee-script/register')

async = require("async")
require("./backbone-sync-riak")
BackgroundJob = require("models/background-job")

reportError = (err,obj, meta)->
    if err
        console.log("Error updating background job:", err)

processing = false
processAllTasks = ()->
    return if processing
    processing = true
    console.info("Checking for new jobs")
    newTasks = new Backbone.Collection([], {model: BackgroundJob})
    newTasks.fetch({
        query: {status: "NEW"}
        error: (err)->
            console.log("Error loading background jobs:", err)
        success: ->
            async.each(newTasks.models, processTask, (err)->
                if err
                    console.log("Error running background job:", err)
                processing = false
            )
    })

processTask = (task, callback)->
    task.fetch({
        error: (err)->
            return callback(err)
        success: ->
            if task.get("status") isnt "NEW"
                return callback()

            console.info("Starting background job: #{task.title()}")
            task.save({status: "WORKING"}, {wait: true})

            try
                handler = require("./background-job-handlers/" + task.get('type'))
            catch e
                task.save({"NO_HANDLER"}, {wait: true})
                return callback("no handler for #{task.get('type')}: " + e)

            handler(task, (err)->
                if err
                    task.set({
                        status: "FAILED"
                        error: err
                    })
                else
                    task.set({status: "FINISHED"})

                console.info("#{task.get('status')}: #{task.title()}")
                task.save({}, {wait: true})
                 # This should trigger post-commit handlers that can see tha change of state
            )
    })

startWorker = (interval=10)->
    setInterval(processAllTasks, interval * 1000)
    processAllTasks()

module.exports = startWorker

if module is require.main
    startWorker(process.env.WORKER_INTERVAL)
