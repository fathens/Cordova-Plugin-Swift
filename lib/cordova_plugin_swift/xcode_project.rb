require 'xcodeproj'

class XcodeProject
    attr_accessor :build_settings, :sources_pattern

    def initialize
        @build_settings = {}
        @sources_pattern = "*.swift"
    end

    def write(project_name)
        log_header "Write #{project_name}.xcodeproj"

        project = Xcodeproj::Project.new "#{project_name}.xcodeproj"
        target = project.new_target(:framework, project_name, :ios)
        project.recreate_user_schemes

        project.targets.each do |target|
            group = project.new_group "Sources"
            sources = Dir.glob(@sources_pattern).map { |path|
                log "Adding source to #{target.name}: #{path}"
                group.new_file(path)
            }
            target.add_file_references(sources)

            target.build_configurations.each do |conf|
                @build_settings.each do |key, value|
                    log "Set #{target.name}(#{conf.name}) #{key}=#{value}"
                    conf.build_settings[key] = value
                end
            end
        end

        project.save
        return project_name
    end
end
