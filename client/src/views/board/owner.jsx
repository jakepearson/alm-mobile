/** @jsx React.DOM */
var React = require('react');
var utils = require('lib/utils');
var ReactView = require('views/base/react_view');

module.exports = ReactView.createBackboneClass({
  render: function() {
    var m = this.props.model,
        ownerName,
        profileImageStyle = {},
        profileImage = '';

    if (m.get('Owner')) {
      ownerName = m.get('Owner')._refObjectName;
      profileImageStyle.backgroundImage = "url(" + utils.getProfileImageUrl(m.get('Owner')._ref, 50) + ")";
    } else {
      ownerName = "No owner";
      profileImage = <div className="picto icon-user-add"/>;
    }
    return (
      <div className="field owner">
        <div className="owner-name" role="link" aria-label={ "Owner. " + ownerName }>
          {ownerName}
        </div>
        <div className="profile-image" style={profileImageStyle} aria-hidden="true">{profileImage}</div>
      </div>
    );
  }
});
