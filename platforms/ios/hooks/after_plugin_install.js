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
	var pluginDir = path.join(context.opts.projectRoot, 'plugins', context.opts.plugin.id);
	var hooksDir = path.join(make_platform_dir(pluginDir), 'hooks');
	
	var addHook = function() {
		var XmlHelpers = context.requireCordovaModule("cordova-lib/src/util/xml-helpers");
		var et = context.requireCordovaModule('elementtree');
		
		var configFile = path.join(context.opts.projectRoot, 'config.xml');
		var xml = XmlHelpers.parseElementtreeSync(configFile);
		log('Processing XML: ' + JSON.stringify(xml, null, '\t'));
		
		var getParent = function(tag, name) {
			log('getParent: ' + tag + '(name=' + name + ')');
			var list = xml.findall(tag);
			log('Finding ios in: ' + list);
			var ios;
			list.forEach(function(e) {
				if (e.get('name') === name) ios = e;
			});
			log('Found platform(name=ios): ' + ios);
			if (!ios) {
				log('Creating tag: ' + tag + '(name=' + name + ')');
				ios = el.makeelement(tag, {name: name});
				xml.append(ios);
			}
			return ios;
		}
		var child = et.XML('<hook type="after_plugin_add" src="' + path.join(hooksDir, 'add-bridging_header.sh') + '" />');
		getParent('platform', 'ios').append(child);
		
		fs.writeFileSync(configFile, xml.write({indent: 4}), 'utf-8');
	}

	var main = function() {
		log("################################ Start preparing\n");
		addHook();

		var script = path.join(hooksDir, 'after_plugin_install.sh');
		var child = child_process.execFile(script, [ context.opts.plugin.id ], {
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
