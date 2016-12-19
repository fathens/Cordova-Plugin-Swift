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
end

class Pod < ElementStruct
    attr_accessor :name, :version, :path, :git, :branch, :tag, :commit, :podspec, :subspecs

    def initialize(params = {})
        super
    end

    def bridging_headers
        @bridging_headers ||= sub_elements('bridging-header').map { |e|
            BridgingHeader.new(element: e)
        }
    end

    def to_s
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
    attr_accessor :ios_version, :swift_version

    def initialize(params = {})
        super
    end

    def pods
        @pods ||= sub_elements('pod').map { |e|
            Pod.new(element: e)
        }
    end

    def write(target_name)
        log_header "Write Podfile"

        target = $PLATFORM_DIR/'Podfile'
        File.open(target, "w") { |dst|
            dst.puts "platform :ios,'#{@ios_version}'"
            dst.puts "swift_version = #{@swift_version}"
            dst.puts "use_frameworks!"
            dst.puts()
            dst.puts "target '#{target_name}' do"
            dst.puts @pods.map { |pod|
                "    #{pod}"
            }
            dst.puts "end"
        }
    end
end

class BridgingHeaderFile
    def initialize(all)
        @imports = all.map { |x| x.import }.compact.uniq
    end

    def write(file)
        if @imports.empty?
            return nil
        else
            File.open(file, "w") { |dst|
                dst.puts @imports.map { |x|
                    "#import <#{x}>"
                }
            }
            return file
        end
    end
end
