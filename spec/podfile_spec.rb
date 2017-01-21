require "spec_helper"

TMP_DIR = Pathname.pwd/'.tmp-podfile'
def mk_tmp
    TMP_DIR/Random.rand(1000).to_s
end
def mk_plugin(base_dir, content)
    file = base_dir/'plugins'/Random.rand(1000).to_s/'plugin.xml'
    FileUtils.mkdir_p(file.dirname)
    file.write content
    file.realpath
end

describe 'Podfile' do
    context "when no element" do
        base_dir = mk_tmp
        file = mk_plugin base_dir, "<something />"
        podfile = Podfile.from_pluginxml(file)
        it { expect(podfile).to be nil }
    end

    context "when bad xml" do
        base_dir = mk_tmp
        file = mk_plugin base_dir, "hogehoge"
        result = begin
            Podfile.from_pluginxml(file)
        rescue => ex
            ex
        end
        it { expect(result).to be nil }
    end

    context "when find one" do
        base_dir = mk_tmp
        file = mk_plugin base_dir, <<~EOF
        <plugin>
            <platform name="ios">
                <framework src='Hoge' type="podspec" spec="~> 0.1.2">
                    <bridging-header import="Some/Some.h" />
                </framework>
            </platform>
        </plugin>
        EOF
        podfile = Podfile.from_pluginxml(file)
        it { expect(podfile.pods.size).to be 1 }
        it { expect(podfile.pods.first.src).to eq 'Hoge' }
        it { expect(podfile.pods.first.spec).to eq '~> 0.1.2' }
        it { expect(podfile.pods.first.bridging_headers.size).to be 1 }
        it { expect(podfile.pods.first.bridging_headers.first.to_s).to eq '#import <Some/Some.h>' }
    end

    context "when gathering headers" do
        base_dir = mk_tmp
        file_a = mk_plugin base_dir, <<~EOF
        <plugin>
            <platform name="ios">
                <framework src='Hoge' type="podspec" spec="~> 0.1.2">
                    <bridging-header import="Some/Some.h" />
                </framework>
            </platform>
        </plugin>
        EOF
        file_b = mk_plugin base_dir, <<~EOF
        <plugin>
            <platform name="ios">
                <framework src='Soge' type="podspec" spec="~> 3.2.1">
                    <bridging-header import="Pome/Pome.h" />
                </framework>
            </platform>
        </plugin>
        EOF
        file_bad = mk_plugin base_dir, "bababaaad"
        headers = Podfile.bridging_headers([file_a, file_bad, file_b])
        it { expect(headers.size).to be 2 }
        it { expect(headers[0]).to eq "#import <Some/Some.h>" }
        it { expect(headers[1]).to eq "#import <Pome/Pome.h>" }
    end

    after :all do
        puts "Deleting tmp dir..."
        FileUtils.rm_rf(TMP_DIR)
    end
end
