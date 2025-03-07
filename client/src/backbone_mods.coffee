$ = require 'jquery'
_ = require 'underscore'
Backbone = require 'backbone'
app = require 'application'
appConfig = require 'app_config'

methodMap =
  'create': 'POST',
  'update': 'POST', #'PUT',
  'patch':  'POST', #'PATCH',
  'delete': 'DELETE',
  'read':   'GET'

origSync = Backbone.sync
# Copied from backbone-1.0.0.js
Backbone.sync = (method, model, options = {}) ->
  headers = options.headers || {}
  headers["X-Requested-By"] = "Rally" unless model.typePath == '__schema__'
  headers["X-RallyIntegrationName"] = appConfig.appName
  
  # Rally Override!
  options.xhrFields =
    withCredentials: true

  options.headers = headers

  type = methodMap[method]

  # Default options, unless specified.
  _.defaults(options, {
    emulateHTTP: Backbone.emulateHTTP,
    emulateJSON: Backbone.emulateJSON
  })

  # Default JSON-request options.
  params =
    type: type
    dataType: 'json'

  # Ensure that we have a URL.
  if !options.url
    params.url = _.result(model, 'url') || urlError()

  # Rally Override! ALM WSAPI adds /create to create URL
  params.url += '/create' if method is 'create'

  # Ensure that we have the appropriate request data.
  if (!options.data? && model && (method == 'create' || method == 'update' || method == 'patch'))
    params.contentType = 'application/json'
    params.data = JSON.stringify({model: (options.attrs or model.toJSON(options))}) #Rally Override!

    # Rally Override!
    params.url += "?key=#{app.session.getSecurityToken()}"
    params.url += "&fetch=#{options.fetch}" if options.fetch?

  # For older servers, emulate JSON by encoding the request into an HTML-form.
  if options.emulateJSON
    params.contentType = 'application/x-www-form-urlencoded'
    params.data = if params.data then {model: params.data} else {}

  # For older servers, emulate HTTP by mimicking the HTTP method with `_method`
  # And an `X-HTTP-Method-Override` header.
  if (options.emulateHTTP && (type == 'PUT' || type == 'DELETE' || type == 'PATCH'))
    params.type = 'POST'
    if options.emulateJSON
      params.data._method = type
    beforeSend = options.beforeSend
    options.beforeSend = (xhr) ->
      xhr.setRequestHeader('X-HTTP-Method-Override', type)
      if beforeSend
        return beforeSend.apply(this, arguments)

  # Don't process data on a non-GET request.
  if params.type != 'GET' && !options.emulateJSON
    params.processData = false

  # If we're sending a `PATCH` request, and we're in an old Internet Explorer
  # that still has ActiveX enabled by default, override jQuery to use that
  # for XHR instead. Remove this line when jQuery supports `PATCH` on IE8.
  if (params.type == 'PATCH' && window.ActiveXObject &&
        !(window.external && window.external.msActiveXFilteringEnabled))
    params.xhr = ->
      return new ActiveXObject("Microsoft.XMLHTTP")
    

  # Rally override
  params.data ?= {}
  params.data.pagesize ?= 50

  metricsData = app.aggregator.beginDataRequest model, params.url
  _.assign options.headers, metricsData.xhrHeaders

  error = options.error
  options.error = (xhr, status, thrown) ->
    app.aggregator.endDataRequest model, xhr, metricsData.requestId
    error?(xhr, status, thrown)
    model.trigger('error', model, xhr, options) unless options.silent
    if xhr.status is 401 or xhr.status is 0 or status.indexOf('Not authorized') > -1
      app.session.logout()
      window.loginError = "Your session has expired. Please login again."
      Backbone.history.navigate('/login', {trigger: true, replace: true})

  success = options.success
  options.success = (resp, status, xhr) ->
    app.aggregator.endDataRequest model, xhr, metricsData.requestId
    updateResultObj = (resp.OperationResult || resp.CreateResult)
    errors = updateResultObj?.Errors
    if errors?.length > 0
      options.error(xhr, errors[0], resp)
    else
      success?(resp, status, xhr)

  # Make the request, allowing the user to override any Ajax options.
  xhr = options.xhr = Backbone.ajax(_.extend(params, options))
  model.trigger('request', model, xhr, options)
  xhr
