require_relative 'cordova_plugin_swift/bridging_headers'
require_relative 'cordova_plugin_swift/xcode_project'

def log(msg)
    puts msg
end

def log_header(msg)
    log "################################"
    log "#### #{msg}"
end
