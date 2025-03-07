_ = require 'underscore'
React = require 'react'
utils = require 'lib/utils'

focusEditor = ->
  if @isEditMode() && @_isExistingObject()
    @$('.editor').focus();

module.exports = {
  componentDidMount: focusEditor
  componentDidUpdate: focusEditor

  getAllowedValues: ->
    av = @props.allowedValues
    av && _.map(av, (value) ->
      value: if _.isObject(value.AllowedValueType) then value._ref else value.StringValue
      label: value.StringValue
    )

  getFieldValue: ->
    @props.value || @props.item.get(@props.field)

  getFieldDisplayValue: ->
    val = @getFieldValue()
    if _.isObject(val) then val._refObjectName else val

  getFieldId: ->
    "#{utils.toCssClass(@props.field)}-field"

  getFieldAttribute: ->
    @props.item.getAttribute(@props.field)

  getFieldDisplayName: ->
    @getFieldAttribute().Name

  getFieldAriaLabel: ->
    fieldDisplayName = @getFieldDisplayName()
    label = "#{fieldDisplayName} field. "
    label += if @getFieldAttribute().AttributeType == "COLLECTION"
      fieldValue = @getFieldValue()
      (if fieldValue then "This item has #{fieldValue.Count} #{fieldDisplayName}" else "This item is still loading") + ". Click to view and add #{fieldDisplayName}."
    else
      "Current value is #{@getFieldDisplayValue()}. Click to Edit."
    label
    
  saveModel: (updates, opts) ->
    if @_isExistingObject()
      @setState( editMode: false )
    @publishEvent 'saveField', updates, opts

  isEditMode: ->
    if @state?.editMode? then @state.editMode else @props.editMode

  startEdit: ->
    @publishEvent 'startEdit', this, @props.field

  endEdit: (event) ->
    try
      value = (@parseValue || @_parseValue)(event.target.value)
      field = @props.field
      event.preventDefault()
      if @props.item.get(field) isnt value
        modelUpdates = {}
        modelUpdates[field] = value
        @saveModel modelUpdates
    catch e

  _parseValue: (value) ->
    val = value
    if @props.inputType == 'number'
      val = _.parseInt(value)
      throw new Error(value + ' is not a number') if val == NaN

    val

  onKeyDown: (event) ->
    switch event.which
      when @keyCodes.ENTER_KEY then @endEdit event
      when @keyCodes.ESCAPE_KEY then @setState editMode: false

  getInputMarkup: ->
    React.DOM.input(
      type: @props.inputType || "text"
      className: "editor #{@props.field}"
      placeholder: @props.field
      defaultValue: @getFieldValue()
      onBlur: @endEdit
      onKeyDown: @onKeyDown
    )

  getAllowedValuesSelectMarkup: ->
    field = @props.field
    options = _.map @getAllowedValues(), (val) ->
      value = val.value
      label = val.label || 'None'
      React.DOM.option( {value: value,  key: field + value },  label )

    defaultValue = @getFieldValue()
    if _.isObject(defaultValue)
      defaultValue = defaultValue._ref
    
    React.DOM.select(
      {
        className: "editor " + @props.field
        defaultValue: defaultValue
        onBlur: @endEdit
        onKeyDown: @onKeyDown
      },
      options
    )

  getEmptySpanMarkup: ->
    React.DOM.span(
      dangerouslySetInnerHTML:
        __html: '&nbsp;'
    )

  _isExistingObject: -> @props.item.get('_ref')
}
