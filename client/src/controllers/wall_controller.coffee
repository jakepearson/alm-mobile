_ = require 'underscore'
app = require 'application'
utils = require 'lib/utils'
SiteController = require 'controllers/base/site_controller'
WallView = require 'views/wall/wall'
WallCreateView = require 'views/wall/create'
WallSplashView = require 'views/wall/splash'
PortfolioItemModelFactory = require 'lib/portfolio_item_model_factory'
Preferences = require 'collections/preferences'
Projects = require 'collections/projects'
UserStories = require 'collections/user_stories'
Project = require 'models/project'

module.exports = class WallController extends SiteController
  create: ->
    projectsFetch = Projects.fetchAll()
    @view = @renderReactComponent WallCreateView, region: 'main', model: Projects::projects, changeOptions: 'complete'
    @subscribeEvent 'createwall', @createWall
    projectsFetch.then => @markFinished()

  splash: ->
    prefs = new Preferences()
    prefs.clientMetricsParent = this
    projects = new Projects()
    projects.clientMetricsParent = this
    @view = @renderReactComponent WallSplashView, region: 'main', model: projects
    @subscribeEvent 'selectProject', @onSelectProject
    @subscribeEvent 'showCreateWall', @showCreateWallPage

    prefs.fetchWallPrefs().then =>
      queryString = utils.createQueryFromCollection(prefs, 'ObjectID', 'OR', (pref) ->
        prefName = pref.get('Name')
        prefName.substring(prefName.indexOf('.') + 1)
      )

      projects.fetchAllPages(
        data:
          fetch: 'Name'
          query: queryString
      ).then => @markFinished()

  show: (project) ->
    @updateTitle "Enterprise Backlog for ..."

    PortfolioItemModelFactory.getCollection(1).then (initiativesModel) =>
      @initiatives = new initiativesModel()
      @initiatives.clientMetricsParent = this

      PortfolioItemModelFactory.getCollection(0).then (featuresModel) =>
        @features = new featuresModel()
        @features.clientMetricsParent = this

        @userStories = new UserStories()
        @userStories.clientMetricsParent = this

        @view = @renderReactComponent WallView, showLoadingIndicator: true, model: @initiatives, region: 'main'
        @subscribeEvent 'cardclick', @onCardClick
        @subscribeEvent 'headerclick', @onHeaderClick
        
        prefs = new Preferences()
        prefs.clientMetricsParent = this
        prefFetch = prefs.fetchWallPref(project)

        @whenProjectIsLoaded project: project, showLoadingIndicator: false, fn: =>

          $.when(prefFetch).then =>
            if !prefs.length
              @initiatives.trigger('add')
              @markFinished()

            pref = prefs.first()
            chosenStates = @getChosenStates(pref)
            @updateTitle "Enterprise Backlog for #{app.session.getProjectName()}"
            projectRef = "/project/#{project}"#334329159'#12271

            initiativesAndFeaturesPromise = $.when(
              @fetchInitiatives(projectRef, chosenStates)
              @fetchFeatures(projectRef)
            )
            userStoriesFetchPromise = @fetchUserStories(projectRef)
            
            initiativesAndFeaturesPromise.then =>
              if @initiatives.isEmpty()
                @initiatives.trigger('add')
                @markFinished()
              else
                @features.each (f) =>
                  parentRef = f.get('Parent')._ref
                  initiative = @initiatives.find _.isAttributeEqual('_ref', parentRef)

                  if initiative?
                    initiative.features ?= new featuresModel()
                    initiative.features.add f
                
                @initiatives.trigger('add')

                userStoriesFetchPromise.then =>
                  @userStories.each (us) =>
                    parentRef = us.get('PortfolioItem')._ref
                    feature = @features.find _.isAttributeEqual('_ref', parentRef)

                    if feature?
                      feature.userStories ?= new UserStories()
                      feature.userStories.add us

                  @initiatives.trigger('add')
                  @markFinished()

  fetchInitiatives: (projectRef, chosenStates) ->
    statesQuery = utils.createQueryFromCollection(chosenStates, 'State.Name', 'OR', (item) ->
      "\"#{item}\""
    )
    @initiatives.fetchAllPages
      data:
        fetch: 'FormattedID'
        query: statesQuery
        order: 'Rank ASC'
        project: projectRef
        projectScopeUp: false
        projectScopeDown: true

  fetchFeatures: (projectRef) ->
    @features.fetchAllPages
      data:
        shallowFetch: 'Parent,FormattedID',
        query: "(Parent != null)",
        order: 'Rank ASC'
        project: projectRef
        projectScopeUp: false
        projectScopeDown: true

  fetchUserStories: (projectRef) ->
    @userStories.fetchAllPages
      data: 
        shallowFetch: 'Release,Iteration,PortfolioItem,ScheduleState',
        query: "(PortfolioItem != null)",
        order: 'Rank ASC'
        project: projectRef
        projectScopeUp: false
        projectScopeDown: true

  onSelectProject: (projectRef) ->
    @redirectTo "/wall/#{utils.getOidFromRef(projectRef)}"

  onCardClick: (oid, type) ->
    mappedType = 'portfolioitem'
    @redirectTo "#{mappedType}/#{oid}"

  onHeaderClick: (view, model) ->
    @redirectTo utils.getDetailHash(model)

  showCreateWallPage: ->
    @redirectTo "/wall/create"

  createWall: (wallInfo) ->
    prefs = new Preferences()
    prefs.clientMetricsParent = this
    user = app.session.get('user')
    prefs.updateWallPreference(user, wallInfo).then =>
      @redirectTo "/wall/#{utils.getOidFromRef(wallInfo.project.get('_ref'))}"

  getChosenStates: (pref) ->
    JSON.parse(pref.get('Value')).chosenStates
