they = require 'ssh2-they'
backmeup = require '../lib/index'
util = require 'util'
moment = require 'moment'


describe 'backmeup', () ->
  before (next) ->
# things to do before this battery of tests
  after (next) ->
# things to do after this battery of tests
  beforeEach (next) ->
# things to do before each test
  afterEach (next) ->
# things to do after each test

# it.only 'toto', () -> ### Will only exec this test
# it.skip 'toto', () -> ### Will skip this test

ssh = null

it "backup #{__dirname}/dataset-tmp with tar & gz", (next) ->
  options =
    name: 'todl'
    source: "#{__dirname}/dataset-tmp"
    destination: "#{__dirname}/backups"
  backmeup.backup ssh, options, (err, done, info) ->
    console.log "info: #{util.inspect info}"
    next err

it "backup #{__dirname}/dataset-tmp/data2 without tar", (next) ->
  options =
    name: '2'
    source: "#{__dirname}/dataset-tmp/"
    filter: "data2"
    destination: "#{__dirname}/backups"
    archive: false
  backmeup.backup ssh, options, (err, done, info) ->
    console.log err if err?
    console.log info
    next err

it "backup #{__dirname}/dataset-tmp/[data2,data3] without tar", (next) ->
  options =
    name: '3'
    source: "#{__dirname}/dataset-tmp/"
    filter: ["data2","data3"]
    destination: "#{__dirname}/backups"
    archive: false
  backmeup.backup ssh, options, (err, done, info) ->
    console.log err if err?
    console.log info
    next err

it "backup #{__dirname}/dataset-tmp/ without tar", (next) ->
  options =
    name: '4'
    source: "#{__dirname}/dataset-tmp/"
    destination: "#{__dirname}/backups"
    archive:false
  backmeup.backup ssh, options, (err, done, info) ->
    console.log err if err?
    console.log info
    next err

it "backup #{__dirname}/dataset-tmp/ with tar, without compression", (next) ->
  options =
    name:'5'
    source: "#{__dirname}/dataset-tmp/"
    destination: "#{__dirname}/backups"
    compress: false
    retention:
      count: 17
      date: '2014-12-29-00:00:00'
  backmeup.backup ssh, options, (err, done, info) ->
    console.log err if err?
    console.log info
    next err

it "backup #{__dirname}/dataset-tmp/data2 with tar & xz", (next) ->
  options =
    name:'6'
    source: "#{__dirname}/dataset-tmp/"
    namefilter: "data2"
    destination: "#{__dirname}/backups"
    algorithm: 'xz'
  backmeup.backup ssh, options, (err, done, info) ->
    console.log err if err?
    console.log info
    next err

it 'backup first batch, and cleanup source dir', (next) ->
  options =
    name: '1'
    source: "#{__dirname}/backups/todl/"
    destination: "#{__dirname}/backups"
    archive:false
    clean_source: true
  backmeup.backup null, options, (err, done, info) ->
    console.log err if err?
    console.log info
    next err


it "backup #{__dirname}/dataset-tmp with tar & gz, retention (count)", (next) ->
  options =
    name: '7'
    source: "#{__dirname}/dataset-tmp"
    destination: "#{__dirname}/backups"
    retention:
      count: 3
  backmeup.backup ssh, options, (err, done, info) ->
    console.log "info: #{util.inspect info}"
    next err

it "backup #{__dirname}/dataset-tmp with tar & gz, retention (age)", (next) ->
  options =
    name: '8'
    source: "#{__dirname}/dataset-tmp"
    destination: "#{__dirname}/backups"
    retention:
      age:
        minute: 5
  backmeup.backup ssh, options, (err, done, info) ->
    console.log "info: #{util.inspect info}"
    next err

it "backup #{__dirname}/dataset-tmp with tar & gz, retention (date: now - 5 min, eq to test 8)", (next) ->
  options =
    name: '9'
    source: "#{__dirname}/dataset-tmp"
    destination: "#{__dirname}/backups"
    retention:
      date: moment().subtract(moment.duration {minutes: 5}).format backmeup.dateformat
  backmeup.backup ssh, options, (err, done, info) ->
    console.log "info: #{util.inspect info}"
    next err

it "backup #{__dirname}/dataset-tmp with tar & gz, minimum interval: 5 min", (next) ->
  options =
    name: '10'
    source: "#{__dirname}/dataset-tmp"
    destination: "#{__dirname}/backups"
    interval:
      minutes: 5
  backmeup.backup ssh, options, (err, done, info) ->
    console.log "info: #{util.inspect info}"
    next err