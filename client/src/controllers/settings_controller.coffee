define ->
  $ = require 'jquery'
  _ = require 'underscore'
  app = require 'application'
  utils = require 'lib/utils'
  UserStory = require 'models/user_story'
  SiteController = require 'controllers/base/site_controller'
  SettingsView = require 'views/settings/settings'
  BoardSettingsView = require 'views/settings/board_settings'

  class SettingsController extends SiteController

    show: (params) ->
      @whenLoggedIn ->
        @view = @renderReactComponent SettingsView, region: 'main', model: app.session
        @subscribeEvent 'changeMode', @onChangeMode
        @subscribeEvent 'changeBoardField', @onChangeBoardField
        @subscribeEvent 'changeProject', @onChangeProject
        @subscribeEvent 'changeIteration', @onChangeIteration
        @subscribeEvent 'logout', @onLogout
        @subscribeEvent 'projectready', => @view.forceUpdate()
        @updateTitle "Settings: #{app.session.getProjectName()}"

    board: (params) ->
      @whenLoggedIn ->
        fieldName = UserStory.getFieldDisplayName app.session.get('boardField')
        @view = @renderReactComponent BoardSettingsView,
          region: 'main'
          fieldName: fieldName
          model: app.session
        @subscribeEvent 'columnClick', @onColumnClick

    onChangeMode: (mode) ->
      app.session.set 'mode', mode

    onChangeBoardField: (boardField) ->
      app.session.set 'boardField', boardField
      @redirectTo 'settings/board'

    onChangeProject: (project) ->
      app.session.set 'project', _.find app.session.get('projects').models, _.isAttributeEqual '_ref', project
      @updateTitle "Settings: #{app.session.getProjectName()}"

    onChangeIteration: (iteration) ->
      if iteration == 'null'
        return app.session.set 'iteration', null
      app.session.set 'iteration', _.find app.session.get('iterations').models, _.isAttributeEqual '_ref', iteration

    onColumnClick: (column) ->
      app.session.toggleBoardColumn column

    onLogout: ->
      @redirectTo 'logout'