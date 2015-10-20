#!/usr/bin/env node
var child_process = require('child_process');

function log(msg) {
	process.stdout.write(msg + '\n');
}

module.exports = function(context) {
	var fs = context.requireCordovaModule('fs');
	var path = context.requireCordovaModule('path');
	var deferral = context.requireCordovaModule('q').defer();

	var make_platform_dir = function(base) {
		return path.join(base, 'platforms', 'ios');
	}

	var findHeaders = function() {
		var XmlHelpers = context.requireCordovaModule("cordova-lib/src/util/xml-helpers");
		var et = context.requireCordovaModule('elementtree');
		
		var xmlFile = path.join(context.opts.projectRoot, 'plugins', context.opts.plugin.id, 'plugin.xml');
		log('Loading XML: ' + xmlFilee);
		var xml = XmlHelpers.parseElementtreeSync(xmlFile);
		
		var files = [];
		var list = xml.findall('bridging-header-file');
		list.forEach(function(e) {
			files.push(e.get('src'));
		});
		return files;
	}

	var main = function() {
		log("################################ Start preparing\n");
		headers = findHeaders();

		var script = path.join(path.dirname(context.scriptLocation), 'add-bridging_header.sh');
		var child = child_process.execFile(script, headers, {
			cwd : make_platform_dir(context.opts.projectRoot)
		}, function(error) {
			if (error) {
				deferral.reject(error);
			} else {
				log("################################ Finish preparing\n\n");
				deferral.resolve();
			}
		});
		child.stdout.on('data', function(data) {
			log(data);
		});
		child.stderr.on('data', function(data) {
			process.stderr.write(data);
		});
	}
	main();
	return deferral.promise;
};
