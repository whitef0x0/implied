# Express Mongo Users
md5 = require 'MD5'
uuid = require 'node-uuid'
fs = require 'fs'
async = require 'async'


users = (opts)->
    
    opts.salt ?= 'secret-the-cat'

    app = opts.app
    db = opts.db
    Users = db.collection 'users'
    
    statics = (arr) ->
      arr.forEach (item)->
        app.get '/'+item, (req,res)->
          res.render item,
            req: req

    statics ['signup', 'login', 'reset-password-confirm', 'reset-password-submit']

    # Forward a request based on "then" hints in it.
    goto_next = (req,res)->
      res.redirect req.query.then or req.body.then or '/'

    # Log in
    # HTTP API:
    # @param then - page to redirect to on success.
    # @param onerror - page to redirect to on failure.
    # @param email - user to log in.
    # @param password - the user's password.
    app.post "/login", (req,res) ->
      Users.findOne
        email:req.body.email
        $or: [
          {password: req.body.password}
          {password: md5(req.body.password + opts.salt)}
        ]
      , (err, user)->
        if user
          req.session.email = user.email
          req.flash?("success", "You've been logged in.")
          goto_next req, res
        else
          req.flash?("error", "Email or password incorrect.")
          res.redirect req.body.onerror or req.path

    app.get "/logout", (req, res) ->
      req.session.email = null
      req.flash?("success", "You've been safely logged out")
      goto_next req, res

    app.post "/signup", (req,res) ->
      if req.body.email and req.body.password
        req.body.password = md5(req.body.password + opts.salt)
        # Check if user exists.
        Users.find({email: req.body.email}).toArray (err, users)->
          if users.length is 0
            Users.insert req.body, (err, user)->
              req.session.email = user.email
              req.session.admin = user.admin
              goto_next req, res
          else
            req.flash?("error", "That user already exists.")
            res.render 'signup',
              req: req
      else
        req.flash?("error", "Please enter a username and password.")
        res.render 'signup',
          req: req
    
    server_path = (req)->
      url = req.protocol + "://" + req.host
      if req.port and req.port isnt 80 then url += ":" + req.port
      url

    # Password Forgotten
    app.post "/reset-password-submit", (req,res)->
      Users.findOne {email: req.body.email}, (err, user) ->
        if user
          token = uuid.v4()
          Users.update({_id:user._id}, {$set:{password_reset_token:token}})
          opts.mailer?(
            to: user.email
            subject: "Password Reset"
            body: "Go here to reset your password: http://" + opts.host + "/reset-password-confirm?token=" + token
          )
          console.log 'sent'
          req.flash?("message", "You've been sent an email with instructions on resetting your password.")
          goto_next req, res
        else
          req.flash?("error", "No user with that email address was found.")

    app.post "/reset-password-confirm", (req,res)->
      if req.session.email
        query = {email: req.session.email}
      else
        query = {password_reset_token: req.query.token}
      Users.update query, {$set:{password:req.body.password}}, (err, user) ->
        if err
          req.flash 'error', 'Password reset failed'
        else
          req.flash 'success', 'Password was reset'
        goto_next req, res

admin = (opts)->
    opts.login_url ?= "/login"

    app = opts.app
    db = opts.db
    
    forms = opts.forms or {}
    
    common = require("./common") opts
    staff = common.staff

    app.get "/admin", staff, (req,res) ->
      res.render 'admin/admin',
        req:req
        email: req.session.email

    app.get "/admin/listings", staff, (req,res) ->
      db.collection("listings").find().sort({user_email:1}).toArray (err, records)->
        res.render "admin/admin-listings",
          title: "Admin Listings"
          req: req
          email: req.session.email
          listings: records

    app.post "/admin/listings", staff, (req,res) ->
      update_db = (args, callback)->
        db.collection("listings").update {_id: args._id}, {$set: {mls_listing_num: args.mls_listing_num, test_listing: args.test_listing}}
        callback true

      task_array = []
      db.collection("listings").find().toArray (err, listings)->
        for listing in listings
          new_mls_num = req.body["mls_listing_num#" + listing._id]
          test_listing = req.body["test_listing#" + listing._id]

          task_array.push {_id: listing._id, mls_listing_num: new_mls_num, test_listing: test_listing}

        console.log "this is my task array: ", task_array
        async.concat task_array, update_db, (err, results)->
          console.log "these are my results", results
          if err then console.log "This is my error: ", err
          res.redirect "/admin/listings"

    app.get /// ^ /admin/listing / ([0-9a-z\-]+) /delete $ ///, (req, res) ->
      id = req.params[0]
      db.collection('listings').remove {_id:id}, (err)->
        res.redirect "/admin/listings"

    app.get "/admin/:collection", staff, (req,res) ->
      db.collection(req.params.collection).find().toArray (err, records)->
        res.render "admin-list",
          title: req.params.collection
          form: forms[req.params.collection]
          req: req
          email: req.session.email
          records: records

    app.get "/admin/:collection/:id", staff, (req,res) ->
      db.collection(req.params.collection).findOne {_id: new ObjectId(req.params.id)}, (err, rec)->
        res.render "admin-object",
          title: req.params.collection
          req: req
          form: forms[req.params.collection]
          email: req.session.email
          rec: rec

    app.post "/admin/:collection/:id", staff, (req,res) ->
      db.collection(req.params.collection).update {_id: new ObjectId(req.params.id)}, {$set: req.body}, (err)->
        res.redirect '/admin/'+req.params.collection

    FORMS = 
      pages:
        print: 'paths'
        fields: [
            name:'title'
          ,
            name:'path'
          ,
            name:'content'
            type:'textarea'
          ,
            name:'meta'
        ]

blog = require './blog'

module.exports.init = (opts)->
  if opts.blog
    blog opts

  if opts.users
    users opts

  if opts.admin
    admin opts

