#!/usr/bin/env node

child_process = require('child_process');

var log = function() {
	var args = Array.prototype.map.call(arguments, function(value) {
		if (typeof value === 'string') {
			return value;
		} else {
			return JSON.stringify(value, null, '\t')
		}
	});
	process.stdout.write(args.join('') + '\n');
}

module.exports = function(context) {
	var fs = context.requireCordovaModule('fs');
	var path = context.requireCordovaModule('path');
	var deferral = context.requireCordovaModule('q').defer();
	var async = context.requireCordovaModule(path.join('request', 'node_modules', 'form-data', 'node_modules', 'async'));
	var XmlHelpers = context.requireCordovaModule("cordova-lib/src/util/xml-helpers");
	var et = context.requireCordovaModule('elementtree');

	var installDeps = function(next) {
		async.forEachSeries(['xcodeproj', 'cocoapods'], function(name, next) {
			log('Checking installed ', name);
			child_process.exec('gem which ' + name, function(err, stdout, stderr) {
				if (!stdout) {
					log('Installing gem ', name);
					child_process.exec('gem install ' + name, next);
				} else {
					log(name, ' is already installed.');
					next();
				}
			});
		}, next);
	}
	
	var byConfigXml = function(next) {
		var configFile = path.join(context.opts.projectRoot, 'config.xml');
		var xml = XmlHelpers.parseElementtreeSync(configFile);
		
		async.parallel(
				[
				function(next) {
					var target;
					xml.findall('preference').forEach(function(e) {
						if (e.get('name') === 'deployment-target') target = e.get('value');
					});
					if (!target) target = "8.0";
					
					var podfile = path.join(context.opts.projectRoot, 'platforms', 'ios', 'Podfile');
					fs.writeFile(podfile, "platform :ios,'" + target + "'\n\n", next);
				},
				function(next) {
					var platform = (function(tag, name) {
						var list = xml.findall(tag);
						var ios;
						list.forEach(function(e) {
							if (e.get('name') === name) ios = e;
						});
						if (!ios) {
							ios = et.Element(tag, {name: name});
							xml.getroot().append(ios);
						}
						return ios;
					})('platform', 'ios');
					
					var addHook = function(name, ext) {
						var script_path = path.join(path.dirname(context.scriptLocation), 'global', [name, ext].join('.'));
						var child = et.Element('hook', {type: name, src: path.relative(context.opts.projectRoot, script_path)});
						platform.append(child);
					}
					addHook('after_prepare', 'rb');
					
					fs.writeFile(configFile, xml.write({indent: 4}), 'utf-8', next);
				}
				 ], next);
	}

	var main = function() {
		async.parallel(
				[
				installDeps,
				byConfigXml
				],
				function(err, result) {
					if (err) {
						log(err);
						deferral.reject(err);
					} else {
						deferral.resolve(result);
					}
				});
	}
	main();
	return deferral.promise;
};
