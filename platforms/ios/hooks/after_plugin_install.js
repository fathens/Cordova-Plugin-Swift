#!/usr/bin/env node
var child_process = require('child_process');

function log(msg) {
	process.stdout.write(msg + '\n');
}

module.exports = function(context) {
	var fs = context.requireCordovaModule('fs');
	var path = context.requireCordovaModule('path');
	var deferral = context.requireCordovaModule('q').defer();
	var XmlHelpers = context.requireCordovaModule("cordova-lib/src/util/xml-helpers");
	var et = context.requireCordovaModule('elementtree');

	var configFile = path.join(context.opts.projectRoot, 'config.xml');
	var xml = XmlHelpers.parseElementtreeSync(configFile);
	
	var platformDir = path.join(context.opts.projectRoot, 'platforms', 'ios')

	var addHook = function() {
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
		
		fs.writeFileSync(configFile, xml.write({indent: 4}), 'utf-8');
	}
	
	var cocoapods = function() {
		var target;
		xml.findall('preference').forEach(function(e) {
			if (e.get('name') === 'deployment-target') target = e.get('value');
		});
		if (!target) target = "8.0";
		
		var podfile = path.join(platformDir, 'Podfile');
		fs.writeFileSync(podfile, "platform :ios,'" + target + "'\n\n");
	}

	var main = function() {
		log("################################ Start preparing");
		addHook();
		cocoapods();

		var child = child_process.execFile('pod', ['install'], {
			cwd : platformDir
		}, function(error) {
			if (error) {
				deferral.reject(error);
			} else {
				process.stdout.write("################################ Finish preparing\n\n")
				deferral.resolve();
			}
		});
		child.stdout.on('data', function(data) {
			process.stdout.write(data);
		});
		child.stderr.on('data', function(data) {
			process.stderr.write(data);
		});
	}
	main();
	return deferral.promise;
};
