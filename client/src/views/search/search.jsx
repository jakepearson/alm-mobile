/** @jsx React.DOM */
var React = require('react');
var ReactView = require('views/base/react_view');
var app = require('application');
var ListView = require('views/listing/list');

module.exports = ReactView.createBackboneClass({

  componentDidMount: function() {
    this._getInputField().focus();
  },

  getInitialState: function() {
    return {
      keywords: this.props.keywords
    };
  },

  render: function() {
    return (
      <div id="search-view">
        <form className="search-form" role="form" onSubmit={ this.onSearch }>
            <div className="input-group">
              <label className="sr-only" htmlFor="search-input">Search keywords</label>
              <input type="text" id="search-input" className="form-control" placeholder="Search keywords" value={ this.state.keywords } onChange={ this.handleChange } ref="input"/>
              <span className="input-group-btn">
                <button type="submit" className="btn btn-primary">Search</button>
              </span>
            </div>
        </form>
        <div className="listing">
          <ListView
            model={this.props.collection}
            noDataMsg="No results matched your search."
            showLoadingIndicator={!!this.props.keywords}
            showItemArtifact={this.props.showItemArtifact}
            changeOptions="sync"/>
        </div>
      </div>
    );
  },

  handleChange: function(event) {
    this.setState({keywords: event.target.value});
  },

  onSearch: function(event) {
    app.aggregator.recordAction({component: this, description: 'search submitted'});
    this.publishEvent('search', this.state.keywords);
    event.preventDefault();
  },

  _getInputField: function() {
    return this.refs.input.getDOMNode();
  }
});
