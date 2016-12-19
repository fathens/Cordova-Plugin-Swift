Gem.find_files("cordova_plugin_swift/**/*.rb").each { |path| require path }

def log(msg)
    puts msg
end

def log_header(msg)
    log "################################"
    log "#### #{msg}"
end
