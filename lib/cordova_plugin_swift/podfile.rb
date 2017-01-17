require 'rexml/document'

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

class BridgingHeader < ElementStruct
    attr_accessor :import

    def initialize(params = {})
        super
    end

    def to_s
        "#import <#{import}>"
    end
end

class Pod < ElementStruct
    attr_accessor :base_dir, :name, :version, :path, :git, :branch, :tag, :commit, :podspec, :subspecs

    def initialize(params = {})
        super
    end

    def bridging_headers
        @bridging_headers ||= sub_elements('bridging-header').map { |e|
            BridgingHeader.new(element: e)
        }
    end

    def merge(other)
        self.base_dir ||= other.base_dir
        self.version = [self.version, other.version].compact.min

        # podspec -> path -> git
        self.podspec ||= other.podspec
        if podspec
            self.path = nil
            self.git = nil
        else
            self.path ||= other.path
            if self.path
                self.git = nil
            else
                self.git ||= other.git
            end
        end

        if self.git
            self.commit ||= other.commit
            self.tag = self.commit ? nil : (self.tag || other.tag)
            self.branch = (self.commit || self.tag) ? nil : (self.branch || other.branch)
        else
            self.branch = nil
            self.tag = nil
            self.commit = nil
        end

        self.subspecs = [self.subspecs, other.subspecs].compact.join(', ')

        return self
    end

    def to_s
        ENV['PLUGIN_DIR'] = self.base_dir&.to_s
        args = [
            or_nil(:name, false),
            or_nil(:version, false),
            or_nil(:path),
            or_nil(:git),
            or_nil(:branch),
            or_nil(:tag),
            or_nil(:commit),
            or_nil(:podspec),
            @subspecs ? ":subspecs => [#{@subspecs.split(',').map {|x| "'#{x.strip}'"}.join(', ')}]" : nil
        ]
        log "Pod #{args}"
        "pod " + args.compact.join(', ').gsub(/\$\{(.+?)\}/) {
            ENV[$1] || $1
        }
    end

    private

    def or_nil(key, with_prefix = true)
        value = send(key)
        prefix = with_prefix ? ":#{key} => " : ""
        return value ? "#{prefix}'#{value}'" : nil
    end
end

class Podfile < ElementStruct
    def self.from_pluginxml(pluginxml)
        xml = REXML::Document.new(File.open(pluginxml))
        e = xml.get_elements('//platform[@name="ios"]/podfile').first
        e ? Podfile.new(base_dir: pluginxml.dirname, element: e) : nil
    end

    attr_accessor :base_dir, :ios_version, :swift_version

    def initialize(params = {})
        super
    end

    def pods
        @pods ||= sub_elements('pod').map { |e|
            Pod.new(base_dir: self.base_dir, element: e)
        }
    end

    def merge(other)
        self.base_dir ||= other.base_dir
        self.ios_version = [self.ios_version, other.ios_version].compact.min
        self.swift_version = [self.swift_version, other.swift_version].compact.min

        other.pods.each { |pod|
            found = self.pods.find { |x| x.name == pod.name }
            if found
                found.merge pod
            else
                pods.push pod
            end
        }
        return self
    end

    def write(target_file, target_name)
        log_header "Write Podfile"

        File.open(target_file, "w") { |dst|
            dst.puts "platform :ios,'#{@ios_version}'"
            dst.puts "swift_version = #{@swift_version}"
            dst.puts "use_frameworks!"
            dst.puts()
            dst.puts "target '#{target_name}' do"
            dst.puts pods.map { |pod|
                "    #{pod}"
            }
            dst.puts "end"
        }
    end
end

class ConfigXml
    def initialize(config_file)
        @xml = REXML::Document.new(File.open(config_file))
    end

    def ios_version
        @ios_version ||= begin
            target = @xml.elements["widget//preference[@name='deployment-target']"]
            target&.attributes ? target&.attributes['value'] : nil
        end
    end

    def application_name
        @application_name ||= @xml.elements["widget/name"]&.text
    end
end