/** @jsx React.DOM */
var moment = require('moment');
var React = require('react');
var ReactView = require('views/base/react_view');
var FieldMixin = require('views/field/field_mixin');

module.exports = ReactView.createBackboneClass({
  mixins: [FieldMixin],
  getDefaultProps: function() {
    return {
      editable: true
    };
  },
  render: function() {
    return (
      <div id={ this.getFieldId() } 
           className={ this.isEditMode() ? 'edit' : 'display' }>
        <div className="well-title control-label" aria-hidden="true">{ (this.props.icon) ? <div className={ "picto icon-" + this.props.icon}/> : '' }{ this.props.label }</div>
        <div className="well well-sm titled-well-sm"
             tabIndex="0"
             onClick={ this._onClick }
             onKeyDown={ this.handleEnterAsClick(this._onClick) }
             role="link"
             aria-label={ this.getFieldAriaLabel() }>
          { this._getValueMarkup() }
        </div>
      </div>
    );
  },

  _onClick: function() {
    if (this.isEditMode()) {
      return;
    }
    if (this.props.routeTo) {
      this.routeTo(this.props.routeTo);
    } else if (this.props.editable) {
      this.startEdit();
    }
  },

  _getValueMarkup: function() {
    if (this.props.valueMarkup) {
      return this.props.valueMarkup;
    }
    if (this.isEditMode()) {
      if (this.getAllowedValues()) {
        return this.getAllowedValuesSelectMarkup();
      } else {
        return this.getInputMarkup();
      }
    } else {
      return this._getDisplayMarkup();
    }
  },

  _getDisplayMarkup: function() {
    var fieldValue = this.getFieldDisplayValue();
    return fieldValue ? this._renderFieldValue(fieldValue) : <span dangerouslySetInnerHTML={{__html: '&nbsp;'}} />;
  },

  _renderFieldValue: function(value) {
    if (this.props.inputType === 'date') {
      return moment(value).format('L');
    }
    return value;
  }
});
