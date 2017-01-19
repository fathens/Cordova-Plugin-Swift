require "spec_helper"

TMP_DIR = Pathname.pwd/'.tmp-bridging_headers'
def mk_tmp
    TMP_DIR/Random.rand(1000).to_s
end

describe 'Finding Bridging-Headers' do
    context "when nothing" do
        base_dir = mk_tmp
        headers = CordovaPluginSwift.bridging_headers(base_dir)
        it { expect(headers.empty?).to be true }
    end

    context "when no element" do
        base_dir = mk_tmp
        plugin = base_dir/'plugins'/'some'/'plugin.xml'
        FileUtils.mkdir_p(plugin.dirname)
        plugin.write "<something />"

        headers = CordovaPluginSwift.bridging_headers(base_dir)
        it { expect(headers.empty?).to be true }
    end

    context "when bad xml" do
        base_dir = mk_tmp
        plugin = base_dir/'plugins'/'some'/'plugin.xml'
        FileUtils.mkdir_p(plugin.dirname)
        plugin.write "hogehoge"

        headers = CordovaPluginSwift.bridging_headers(base_dir)
        it { expect(headers.empty?).to be true }
    end

    context "when find one" do
        base_dir = mk_tmp
        plugin = base_dir/'plugins'/'some'/'plugin.xml'
        FileUtils.mkdir_p(plugin.dirname)
        plugin.write <<~EOF
        <plugin>
            <platform name="ios">
                <framework name='Hoge' type="podspec">
                    <bridging-header import="Some/Some.h" />
                </framework>
            </platform>
        </plugin>
        EOF

        system "cat #{plugin}"
        headers = CordovaPluginSwift.bridging_headers(base_dir)
        it { expect(headers.size).to be 1 }
        it { expect(headers.first).to eq '#import <Some/Some.h>' }
    end

    after :all do
        puts "Deleting tmp dir..."
        FileUtils.rm_rf(TMP_DIR)
    end
end
