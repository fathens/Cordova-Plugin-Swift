#!/usr/bin/env node
var child_process = require('child_process');

function log(msg) {
	process.stdout.write(msg + '\n');
}

module.exports = function(context) {
	var async = context.requireCordovaModule('async');
	var fs = context.requireCordovaModule('fs');
	var path = context.requireCordovaModule('path');
	var deferral = context.requireCordovaModule('q').defer();
	var XmlHelpers = context.requireCordovaModule("cordova-lib/src/util/xml-helpers");
	var et = context.requireCordovaModule('elementtree');

	var byConfigXml = function(next) {
		var configFile = path.join(context.opts.projectRoot, 'config.xml');
		var xml = XmlHelpers.parseElementtreeSync(configFile);
		
		async.waterfall(
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
					var getParent = function(tag, name) {
						var list = xml.findall(tag);
						var ios;
						list.forEach(function(e) {
							if (e.get('name') === name) ios = e;
						});
						log('Found platform(name=ios): ' + ios);
						if (!ios) {
							log('Creating tag: ' + tag + '(name=' + name + ')');
							ios = et.Element(tag, {name: name});
							xml.getroot().append(ios);
						}
						return ios;
					}
					var script_path = path.join(path.dirname(context.scriptLocation), 'add-bridging_header.rb');
					var child = et.Element('hook', {type: "after_prepare", src: path.relative(context.opts.projectRoot, script_path)});
					getParent('platform', 'ios').append(child);
					
					fs.writeFile(configFile, xml.write({indent: 4}), 'utf-8', next);
				}
				 ], next);
	}

	var main = function() {
		async.waterfall(
				[
				byConfigXml
				 ],
				function(err, result) {
					if (err) {
						deferral.reject();
					} else {
						deferral.resolve();
					}
				});
	}
	main();
	return deferral.promise;
};
