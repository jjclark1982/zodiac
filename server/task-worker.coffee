#!/usr/bin/env coffee
require('coffee-script/register')

db = require("./db")
async = require("async")
ServerTask = require("models/server-task")
bucket = ServerTask.prototype.bucket

reportError = (err,obj, meta)->
    if err
        console.log("Error updating task:", err)

processing = false
processAllTasks = ()->
    # return if processing
    processing = true
    console.info("Checking for new tasks")
    db.query(bucket, {status: 'created'}, (err, keys, meta)->
        if err
            console.log("Error reading task:", err)
        async.each(keys, processTask, (err)->
            if err
                console.log("Error running task:", err)
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
            handler = require("./task-handlers/" + task.type)
        catch e
            return callback("no handler for #{task.type}: " + e)


        task.status = "working"
        options = {
            vclock: task.vclock,
            index: {status: task.status}
        }
        console.info("Starting task: #{task.name}")
        db.save("tasks", key, task, options, reportError)

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
