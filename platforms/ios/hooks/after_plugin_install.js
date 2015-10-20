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
	
	var make_platform_dir = function(base) {
		return path.join(base, 'platforms', 'ios');
	}
	var pluginDir = path.join('plugins', context.opts.plugin.id);
	var hooksDir = path.join(make_platform_dir(pluginDir), 'hooks');

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
		var child = et.Element('hook', {type: "after_prepare", src: path.join(hooksDir, 'add-bridging_header.rb')});
		getParent('platform', 'ios').append(child);
		
		fs.writeFileSync(configFile, xml.write({indent: 4}), 'utf-8');
	}
	
	var cocoapods = function() {
		var target;
		xml.findall('preference').forEach(function(e) {
			if (e.get('name') === 'deployment-target') target = e.get('value');
		});
		if (!target) target = "8.0";
		
		var podfile = path.join(make_platform_dir(context.opts.projectRoot), 'Podfile');
		fs.writeFileSync(file_path, "platform :ios,'" + target + "'\n\n"));
	}

	var main = function() {
		log("################################ Start preparing");
		addHook();
		cocoapods();
		log("################################ Finish preparing\n");
		deferral.resolve();
	}
	main();
	return deferral.promise;
};
