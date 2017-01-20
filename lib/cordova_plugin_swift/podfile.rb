require 'rexml/document'

class Podfile
    attr_accessor :pods, :ios_version, :swift_version, :use_frameworks

    def self.from_pluginxml(plugin_file)
        xml = REXML::Document.new(File.open(plugin_file))
        pods = xml.get_elements('//platform[@name="ios"]/framework[@type="podspec"]').map { |x|
            Pod.new(x)
        }
        Podfile.new(pods)
    end

    def initialize(pods)
        @pods = pods
        @use_frameworks = false
    end

    def write(target_file, target_name)
        open(target_file, 'w') do |dst|
            dst.puts "platform :ios, '#{@ios_version}'"
            dst.puts "use_frameworks!" if @use_frameworks
            dst.puts "swift_version = '#{@swift_version}'"
            dst.puts "target '#{target_name}' do"
            dst.puts @pods.map { |x|
                "    #{x}"
            }
            dst.puts "end"
        end
    end
end

class Pod
    attr_accessor :name, :spec, :bridging_headers

    def initialize(framework)
        @name = framework.attributes['src']
        @spec = framework.attributes['spec']
        @bridging_headers = framework.get_elements('//bridging-header').map { |x|
            BridgingHeader.new(x)
        }
    end

    def to_s
        "pod '#{@name}', '#{@spec}'"
    end
end

class BridgingHeader
    def initialize(element)
        @name = element.attributes['name']
    end

    def to_s
        "#import <#{@name}>"
    end
end
