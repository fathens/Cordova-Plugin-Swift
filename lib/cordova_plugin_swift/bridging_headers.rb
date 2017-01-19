require 'rexml/document'

module CordovaPluginSwift
    def self.bridging_headers(base_dir)
        Pathname.glob(base_dir/'plugins'/'*'/'plugin.xml').map { |xmlFile|
            puts "Reading #{xmlFile}"
            begin
                xml = REXML::Document.new(File.open(xmlFile))
                xml.get_elements('//platform[@name="ios"]/framework[@type="podspec"]/bridging-header').map { |e|
                    puts "Found element #{e}"
                    e.attributes['import']
                }
            rescue => ex
                puts "Error on '#{xmlFile}': #{ex.message}"
            end
        }.flatten.compact.uniq.map { |name|
            "#import <#{name}>"
        }
    end
end
