app = require 'application'
Controller = require 'controllers/base/controller'
Preference = require 'models/preference'
LabsNoticeView = require 'views/auth/labs_notice'
LoginView = require 'views/auth/login'

module.exports = class AuthController extends Controller

  logout: (params) ->
    app.session.logout()
    @login()

  login: (params) ->
    @view = @renderReactComponent LoginView
    @subscribeEvent 'submit', @onSubmit
    @markFinished()

  labsNotice: (params) ->
    @view = @renderReactComponent LabsNoticeView
    @subscribeEvent 'accept', @onAccept
    @subscribeEvent 'reject', @onReject
    @markFinished()

  onSubmit: (username, password, rememberme) ->
    app.session.authenticate username, password, (authenticated) =>
      if err?
        app.session.logout()
        @view.showError 'There was an error signing in. Please try again.'
      else
        if authenticated
          @redirectTo '', replace: true
        else
          app.session.logout()
          @view.showError 'The password you have entered is incorrect.'

  onAccept: ->
    app.session.acceptLabsNotice().then =>
      @redirectTo '', replace: true

  onReject: ->
    @redirectTo 'login'
