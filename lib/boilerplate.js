const path = require('path');
const express = require('express');
const session = require('express-session');

module.exports = function(app) {
    var FileStore, MongoDBStore, helmet, store, store_params;
    if (!app.get("upload_dir")) {
        app.set("upload_dir", path.join("/var", app.get("app_name")));
    }
    if (!app.get("view engine")) {
        app.set("view engine", "jade");
    }
    if (process.env.NODE_ENV === 'development') {
        app.locals.pretty = true;
        app.locals.development = true;
    }

    app.use(express.bodyParser());

    /*
     * Use helmet?
     */
    if (app.get('security_headers') === true) {
        helmet = require('helmet');
        app.use(helmet.xframe());
        app.use(helmet.iexss());
        app.use(helmet.contentTypeOptions());
        app.use(helmet.cacheControl());
    }
    app.use(express.cookieParser());
    app.set('session_enabled', (app.get('session_enabled')) || true);
    app.set('session_db_name', (app.get('session_db_name')) || 'session');
    app.set('session_storage', (app.get('session_storage')) || 'mongodb');
    if (app.get('session_enabled') === true) {

        /*
         * Sessions storage using FileStore
         */
        if (app.get('session_storage') === 'filestore') {
            FileStore = require('session-file-store')(session);
            store = new FileStore(session);

            /*
             * Session storage using MongoDB
             */
        } else if (app.get('session_storage') === 'mongodb') {
            if (!app.get('db_name')) {
                console.log('ERROR: mongodb session storage requires a valid db_name set in the app configs');
            } else {
                MongoDBStore = require('connect-mongodb-session')(session);
                store_params = {
                    uri: 'mongodb://' + app.get('db_name'),
                    collection: app.get('session_db_name')
                };
                store = new MongoDBStore(store_params);
                app.set('store', store);

                /*
                 * Invalid session storage
                 */
            }
        } else {
            console.log('ERROR: Invalid session_storage:', app.get('session_storage'));
        }
        if (store) {
            app.use(session({
                secret: (app.get('secret')) || "UNSECURE-STRING",
                store: store,
                resave: false,
                saveUninitialized: false
            }));
        }
    }
    if (app.get('csrf') === true) {
        app.use(express.csrf());
        app.use(function(req, res, next) {
            res.locals.csrf = req.session._csrf;
            return next();
        });
    }
    app.use(function(req, res, next) {
        if (req.query.referrer) {
            req.session.referrer = req.query.referrer;
        }
        return next();
    });
    app.use(express["static"](path.join(app.get('dir'), 'public')));
    app.use(express["static"](app.get("upload_dir")));
    app.locals.process = process;
    app.locals.app = app;

    /*
     * Middleware to make request available to templates.
     */
    return app.use(function(req, res, next) {
        res.locals.req = res.locals.request = req;
        return next();
    });
};

process.on('unhandledRejection', r => console.log(r));
