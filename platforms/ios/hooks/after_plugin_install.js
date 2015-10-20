#!/usr/bin/env node
var child_process = require('child_process');

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
		
		var getParent = function(tag, name) {
			var list = xml.findall('/' + tag);
			var ios = list.find(function(e) {
				return e.get('name') === name;
			});
			process.stdout.write('Found platform(name=ios): ' + ios);
			if (!ios) {
				process.stdout.write('Creating tag: ' + tag + '(name=' + name + ')');
				ios = el.makeelement(tag, {name: name});
				xml.append(ios);
			}
			return ios;
		}
		var child = et.XML('<hook type="after_plugin_add" src="' + path.join(hooksDir, 'add-bridging_header.sh') + " />");
		getParent('platform', 'ios').append(child);
		
		fs.writeFileSync(configFile, xml.write({indent: 4}), 'utf-8');
	}

	var main = function() {
		process.stdout.write("################################ Start preparing\n");
		addHook();

		var script = path.join(hooksDir, 'after_plugin_install.sh');
		var child = child_process.execFile(script, [ context.opts.plugin.id ], {
			cwd : make_platform_dir(context.opts.projectRoot)
		}, function(error) {
			if (error) {
				deferral.reject(error);
			} else {
				process.stdout.write("################################ Finish preparing\n\n");
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
