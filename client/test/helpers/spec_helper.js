var chai = require('chai');
var sinon = require('sinon');
var sinonChai = require('sinon-chai');
var Messageable = require('lib/messageable');
var app = require('application');

chai.use(sinonChai);
window.expect = chai.expect;

var sinonSandboxSetUp = function(spec) {
    if (spec.__sandbox__) {
        return;
    }
    var config = sinon.getConfig(sinon.config);
    config.injectInto = config.injectIntoThis && spec || config.injectInto;
    spec.__sandbox__ = sinon.sandbox.create(config);
  };

var sinonSandboxTearDown = function(spec) {
    spec.__sandbox__.verifyAndRestore();
};

beforeEach(function() {
    sinonSandboxSetUp(this);
    _.extend(this, Messageable);
    app.aggregator = {
        recordAction: this.stub()
    };
});

afterEach(function() {
    sinonSandboxTearDown(this);
});
