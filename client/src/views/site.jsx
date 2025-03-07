/** @jsx React.DOM */
var $ = require('jquery');
var _ = require('underscore');
var React = require('react');
var app = require('application');
var ReactView = require('views/base/react_view');
var HeaderView = require('views/header');
var NavigationView = require('views/navigation/navigation');
var ErrorDialog = require('views/error_dialog');

module.exports = ReactView.createBackboneClass({
  componentDidMount: function() {
    this.publishEvent('!region:register', this, 'header', '#header');
    this.publishEvent('!region:register', this, 'navigation', '#navigation');
    this.publishEvent('!region:register', this, 'main', '#content');
  },
  componentWillUnmount: function() {
    this.publishEvent('!region:unregister', this, 'header');
    this.publishEvent('!region:unregister', this, 'navigation');
    this.publishEvent('!region:unregister', this, 'main');
  },
  render: function() {
    return (
      <div>
        <div className="header-container" id="header">
          <HeaderView/>
        </div>

        <div className="navigation-container page left" id="navigation">
          <NavigationView/>
        </div>

        <div className="page-container page transition center" id="page-container">
            <div className="content-container" id="content">{ this._getContent() }</div>
        </div>
        <ErrorDialog/>
        <div id="mask" style={ {display: "none"} }/>
      </div>
    );
  },

  _getContent: function() {
    return this.props.main;
  }
});
