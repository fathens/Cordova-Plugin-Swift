require_relative 'cordova_plugin_swift/podfile'
require_relative 'cordova_plugin_swift/xcode_project'

def log(msg)
    puts msg
end

def log_header(msg)
    log "################################"
    log "#### #{msg}"
end
