
    exec = require 'ssh2-exec'
    moment = require 'moment'
    path = require 'path'

    dateformat = 'YYYY-MM-DD-HH:mm:ss'

# Backup

## Parameters

backmeup.backup fonction takes up to 5 parameters:

*   `ssh` (object|ssh2)   
    Run the action on a remote server using SSH, an ssh2 instance or an
    configuration object used to initialize the SSH connection.
    If _null_, backup is run locally
*   `opt` (object)
    Option object parameters. Option properties are described below
*   `next` (callback)
    callback called after backup with (err, info), described below

### Option properties

*   `name` (string)
    backup name (MANDATORY)
    default value: randomly generated
*   `source` (string)
    file or directory (path) to copy. Error if _null_ or _undefined_
    default value: _undefined_
*   `destination` (string)
    where the file or directory is copied. No default value. Error if _null_ or _undefined_
    default value: _undefined_ 
*   `filter` (string | array)
    filter files in source. Accept globbing. Source is treated as a directory if exist
    default value: _undefined_
*   `interval` (object | number | string)
    the minimum interval between two backups. If the actual time is before 
    the last backup plus this duration parameter, backup will be skipped.
    See momentjs duration parameter for possible value
*   `archive` (boolean)
    if _false_, source is copied. If _true_ files are archived (tar).
    default value: _true_
*   `compress` (boolean)
    define is archive should be compressed. Ignored if archive is _false_
    defaut value: if archive _true_, else _undefined_
*   `algorithm` (string)
    compression algorithm. Ignored if archive is _false_
    default value: if archive _'gzip'_, else _undefined_
*   `clean_source` (boolean)
    if _true_, source is deleted after backup.
    default value: _false_
*   `ignore_hnameden_files` (boolean)
    if _true_, hnameden files are ignored
    default value: _false_
*   `retention` (object)
    if neither _undefined_ nor _null_, backup.clean will be called. See below
    default value: _undefined_

## Callback parameters

*   `err` (Error)
    Error object if any
*   `done`  (boolean)
    If the backup was executed or not
*   `info` (object)
    backup passes info to a callback. Info contains _options_ properties with default
    and/or generated missing values

## Example

```js
var backmeup = require('backmeup');

backmeup.backup(ssh, {
  name: 'my_backup'
  source: '/etc'     
  filter: 'myfile' | '*.log' | ['file1, 'file2', 'toto/titi'] 
  destination: '/tmp'
  archive: false
  path:               
  filename: %date%.%extension%
  dateformat: 'Y-m-d-H:i:s'
  compress:
  algorithm: 'gzip | bzip2 | lzma'
  extension: 'tgz'
  clean_source: true
  retention: {
    count: 3
    date: '2015-01-01-00:00:00'
    age: 2592000
  }
}, function(err, done, info){
  console.log(info);
});
```

    backup = (ssh, opt, next) ->
      err = new Error 'no backup name' unless opt.name?
      err = new Error 'no source file(s)' unless opt.source?
      err = new Error 'no destination' unless opt.destination?
      return next err, opt if err?

      info = opt
      info.archive ?= true
      info.clean_source ?= false
      now = moment()
      info.dateformat = dateformat
      info.date = now.format info.dateformat
      info.source = path.normalize info.source
      info.destination = path.normalize info.destination
      do_finish = () ->
        if info.archive
          cmd = "mkdir -p #{path.join info.destination, info.name}; "
          info.compress ?= true
          if info.compress
            info.algorithm ?= 'gzip'
            switch
              when info.algorithm is 'gzip'
                c = 'z'
                extension = 'tar.gz'
              when info.algorithm is 'bunzip2'
                c = 'j'
                extension = 'tar.bz2'
              when info.algorithm is 'xz'
                c = 'J'
                extension = 'tar.xz'
          else
            c = ''
            extension = 'tar'
          info.filename = "#{info.date}.#{extension}"
          cmd += "tar -#{c}cvf #{path.join info.destination, info.name, info.filename} -C #{info.source} "
          if info.filter?
            cmd += if Array.isArray info.filter then info.filter.join ' ' else info.filter
          else cmd += '. '
        else
          cmd = "mkdir -p #{path.join info.destination, info.name, info.date}; "
          if info.filter?
            if Array.isArray info.filter
              for elmt,i in info.filter
                cmd += "&& " if i isnt 0
                cmd += "cp -R #{path.join info.source, elmt} #{path.join info.destination, info.name, info.date}"
            else if typeof info.filter is 'string'
              cmd += "cp -R #{path.join info.source, info.filter} #{path.join info.destination, info.name, info.date}" 
            else
              return next new Error 'Incorrect filter type: string or string array only'
          else
            cmd += "cp -R #{info.source} #{path.join info.destination, info.name, info.date}"
        if info.clean_source
          if info.filter?
            if Array.isArray info.filter
              cmd += " && rm -rf"
              cmd += " #{path.join info.source, elmt}" for elmt in info.filter
            else
              cmd += " && rm -rf #{path.join info.source, info.filter}"
          else
            cmd += " && rm -rf #{info.source}"
        info.cmd = cmd
        exec ssh, cmd, (err, _stdout, _stderr) ->
          if err?
            info.done = false
          else
            info.done = true
            if info.retention?
              return clean ssh, info, next if info.retention
          return next err, info.done, info
      if info.interval?
        backups_list ssh, info, (err, info, list) ->
          if err?
            info.done = false
            return next err, info.done, info
          if list.length > 0
            if now.isBefore list.pop().date.add(moment.duration info.interval)
              info.done = false
              return next null, info.done, info
          do_finish()
      else do_finish()

# Cleanup

## Parameters

backmeup.clean fonction takes up to 5 parameters:

*   `ssh` (object|ssh2)
    Run the action on a remote server using SSH, an ssh2 instance or an
    configuration object used to initialize the SSH connection.
    If _null_, backup is run locally
*   `opt` (object)
    Option object parameters. Option properties are described below
*   `next` (callback)
    callback called after backup with (err, info), described below

### Option properties

*   `name` (string)
    backup name/name. Error if _null_ or _undefined_
    default value: randomly generated
*   `destination` (string)
    where the file or directory were copied. No default value. Error if _null_ or _undefined_
    default value: _undefined_
*   `retention` (object)
    Retention parameters. Error if _null_ or _undefined_
    default value: _undefined_
    *   `count` (int)
        max quantity of backups. Ignored if null or undefined
        default value: _undefined_
    *   `date`: (string | int)
        All backup made before this date will be deleted. If string, must be in
        dateformat format
        default value: _undefined_
    *   `age` (object | number | string)
        Max age of backups. 
        See moment.duration constructor parameter for possible values
        default value: _undefined_


## Callback parameters

*   `err` (Error)
    Error object if any
*   `done` (boolean)
    If at least one backup was deleted or not. This value is forced by backup function
*   `info` (object)
    backup passes info to a callback. Info contains _options_ properties with default
    and/or generated missing values

## Example

```js
var backmeup = require('backmeup');

backmeup.clean(ssh, {
  name: 'my_backup'
  
  [...]

  retention: {
    count: 3
    date: '2015-01-01-00:00:00'
    age: 2592000
  }
}, function(err, info){
  console.log(info);
});
```

    clean = (ssh, opt, next) ->
      err = new Error 'no destination ' unless opt.destination?
      err = new Error 'no backup name ' unless opt.name?
      if opt.destination?
        err = new Error 'no property in retention object' unless opt.count? or opt.date? or opt.age?
      else
        err = new Error 'no retention object'
      if err?
        return next err, opt.done, opt if opt.done?
        return next err,false, opt

      info = opt
      info.dateformat = dateformat
      info.date ?= moment().format dateformat
      now = moment info.date, info.dateformat
      backups_list ssh, info, (err, info, list) ->
        if err?
          return next err, info.done, info if info.done?
          return next err, false, info
        todl = []
        for elmt in list
          if info.retention.count?
            if list.length-todl.length > info.retention.count
              todl.push elmt.name
              continue
          if info.retention.age?
            max_date = now.subtract moment.duration info.retention.age
            if elmt.date.isBefore max_date
              todl.push elmt.name
              continue
          if info.retention.date?
            max_date = moment info.retention.date, info.dateformat
            if elmt.date.isBefore max_date
              todl.push elmt.name
              continue

        cmd = "rm -rf #{todl.join ' '}"
        exec ssh, cmd, (err, stdout, stderr) ->
          return next err, info.done, info if info.done?
          return next err, !err?, info

# Backups_list

## Parameters

backmeup.backups_list fonction takes up to 3 parameters:

*   `ssh` (object|ssh2)
    Run the action on a remote server using SSH, an ssh2 instance or an
    configuration object used to initialize the SSH connection.
    If _null_, backup is run locally
*   `opt` (object)
    Option object parameters. Option properties are described below
*   `next` (callback)
    callback called after backup with (err, info), described below

### Option properties

*   `name` (string)
    backup name/name. Error if _null_ or _undefined_
    default value: randomly generated
*   `destination` (string)
    where the file or directory were copied. No default value. Error if _null_ or _undefined_
    default value: _undefined_

## Callback parameters

*   `err` (Error)
    Error object if any
*   `info` (object)
    backup passes info to a callback. Info contains _options_ properties with default
    and/or generated missing values
*   `list` (object array)
    list of backups:
    *   `name` (string) 
        filename'
    *   `date` (Moment object)
        Date. See momentjs for details

## Example

```js
var backmeup = require('backmeup');

backmeup.backups_list(ssh, {
  name: 'my_backup'
  destination: '/tmp/there/'
}, function(err, info, list){
  console.log(info);
  console.log(list);
});
```

    backups_list = (ssh, opt, next) ->
      err = new Error 'no destination ' unless opt.destination?
      err = new Error 'no backup name ' unless opt.name?
      
      return next err, info if err?
      
      info = opt
      info.dateformat ?= dateformat
      info.date ?= moment().format info.dateformat
      exec ssh, "ls --format single-column #{path.join info.destination, info.name}", (err, stdout, stderr) ->
        return next null, info, [] if err?
        list = stdout.split '\n'
        #remove last element, always empty since stdout finishes with a \n
        list.pop()
        moments = []
        for elmt in list
          moments.push
            name: path.join info.destination, info.name, elmt
            date: moment elmt.split('.').shift(), info.dateformat
        next null, info, moments

Exports

    module.exports = {}
    module.exports.backup = backup
    module.exports.clean = clean
    module.exports.backups_list = backups_list
    module.exports.dateformat = dateformat