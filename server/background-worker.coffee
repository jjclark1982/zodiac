#!/usr/bin/env coffee
require('coffee-script/register')

db = require("./db")
async = require("async")
BackgroundJob = require("models/background-job")
bucket = BackgroundJob.prototype.bucket

reportError = (err,obj, meta)->
    if err
        console.log("Error updating background job:", err)

processing = false
processAllTasks = ()->
    # return if processing
    processing = true
    console.info("Checking for new jobs")
    db.query(bucket, {status: 'created'}, (err, keys, meta)->
        if err
            console.log("Error reading background job:", err)
        async.each(keys, processTask, (err)->
            if err
                console.log("Error running background job:", err)
            processing = false
        )
    )

processTask = (key, callback)->
    db.get(bucket, key, {}, (err, task, meta)->
        if err
            return callback(err)
        if task.status isnt "created"
            return callback()

        try
            handler = require("./background-job-handlers/" + task.type)
        catch e
            return callback("no handler for #{task.type}: " + e)


        task.status = "working"
        options = {
            vclock: task.vclock,
            index: {status: task.status}
        }
        console.info("Starting background job: #{task.name}")
        db.save(bucket, key, task, options, reportError)

        handler(task, (err)->
            if err
                task.status = "failed"
                task.error = err
            else
                task.status = "finished"

            options.index.status = task.status
            console.info("#{task.status}: #{task.name}")
            db.save(bucket, key, task, options, reportError)
        )

    )

startWorker = (interval=10)->
    setInterval(processAllTasks, interval * 1000)
    processAllTasks()

module.exports = startWorker

if module is require.main
    startWorker(process.env.WORKER_INTERVAL)
