require 'rexml/document'

class Podfile < ElementStruct
    attr_accessor :pods, :ios_version, :swift_version, :use_frameworks

    def self.from_pluginxml(plugin_file)
        xml = REXML::Document.new(File.open(plugin_file))
        e = xml.elements['//platform[@name="ios"]']
        Podfile.new(element: e)
    end

    def initialize(params = {})
        super
    end

    def pods
        @pods ||= sub_elements('framework[@type="podspec"]').map { |e|
            Pod.new(element: e)
        }
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

class Pod < ElementStruct
    attr_accessor :src, :name, :spec, :bridging_headers

    def initialize(params = {})
        super
    end

    def bridging_headers
        @bridging_headers ||= sub_elements('bridging-header').map { |e|
            BridgingHeader.new(element: e)
        }
    end

    def to_s
        "pod '#{@src || @name}', '#{@spec}'"
    end
end

class BridgingHeader < ElementStruct
    attr_accessor :import

    def initialize(params = {})
        super
    end

    def to_s
        "#import <#{@import}>"
    end
end

class ElementStruct
    def self.accessors(clazz)
        keys = clazz.instance_methods
        names = keys.map { |key| key.to_s }
        keys.select { |key|
            key.to_s.match(/^\w+$/) && names.include?("#{key}=")
        }
    end

    def initialize(params = {})
        @element = params[:element]
        ElementStruct.accessors(self.class).each { |key|
            value = params[key] || attributes(key.to_s)
            send "#{key}=", value
        }
    end

    def attributes(name)
        @element ? @element.attributes[name] : nil
    end

    def sub_elements(xpath)
        @element ? @element.get_elements(xpath) : []
    end
end
