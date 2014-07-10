twilioAccountSid = process.env.TWILIO_ACCOUNT_SID
twilioAuthToken = process.env.TWILIO_AUTH_TOKEN
twilio =  require('twilio')(twilioAccountSid, twilioAuthToken)

module.exports = handleTask = (task, callback)->
    partner = task.partner

    twilio.messages.create({
        body: "Thank you for considering Zodiac!",
        to:  partner.phone_number,
        from: "+14085551212"
     }, (err, text)->
        if err
            task.status = "failed"
            return callback("Twilio error:" + err)
        else
            task.status = "finished"
            task.response = "TWILIO: " + text
            callback()
    )

# TODO: standardize unit-testing structure for task handlers
testHandler = ()->
    exampleTask = {}
    handleTask(exampleTask, (err)->
        console.log("done")
    )
