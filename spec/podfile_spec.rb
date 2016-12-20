require "spec_helper"

describe 'Podfile base_dir merge' do
    context "when empty to empty" do
        a = Podfile.new()
        a.merge Podfile.new()
        it { expect(a.base_dir).to be_nil }
    end
    context "when empty to value" do
        a = Podfile.new()
        a.merge Podfile.new(base_dir: "/path_to_somewhere")
        it { expect(a.base_dir).to eq("/path_to_somewhere") }
    end
    context "when value to empty" do
        a = Podfile.new(base_dir: "/path_to_somewhere")
        a.merge Podfile.new()
        it { expect(a.base_dir).to eq("/path_to_somewhere") }
    end
end

describe 'Podfile ios_version merge' do
    context "with upper" do
        a = Podfile.new(ios_version: '8.0')
        a.merge Podfile.new(ios_version: '9.0')
        it { expect(a.ios_version).to eq('8.0') }
    end
    context "with under" do
        a = Podfile.new(ios_version: '8.0')
        a.merge Podfile.new(ios_version: '7.0')
        it { expect(a.ios_version).to eq('7.0') }
    end
    context "with same" do
        a = Podfile.new(ios_version: '8.0')
        a.merge Podfile.new(ios_version: '8.0')
        it { expect(a.ios_version).to eq('8.0') }
    end
    context "with short" do
        a = Podfile.new(ios_version: '8.0.0')
        a.merge Podfile.new(ios_version: '8.0')
        it { expect(a.ios_version).to eq('8.0') }
    end
    context "with long" do
        a = Podfile.new(ios_version: '8.0')
        a.merge Podfile.new(ios_version: '8.0.0')
        it { expect(a.ios_version).to eq('8.0') }
    end
    context "with same width and littler" do
        a = Podfile.new(ios_version: '8.1')
        a.merge Podfile.new(ios_version: '8.0')
        it { expect(a.ios_version).to eq('8.0') }
    end
    context "with shorter and greater" do
        a = Podfile.new(ios_version: '8.0.1')
        a.merge Podfile.new(ios_version: '8.1')
        it { expect(a.ios_version).to eq('8.0.1') }
    end
end

describe 'Podfile swift_version merge' do
    context "with upper" do
        a = Podfile.new(swift_version: '8.0')
        a.merge Podfile.new(swift_version: '9.0')
        it { expect(a.swift_version).to eq('8.0') }
    end
    context "with under" do
        a = Podfile.new(swift_version: '8.0')
        a.merge Podfile.new(swift_version: '7.0')
        it { expect(a.swift_version).to eq('7.0') }
    end
    context "with same" do
        a = Podfile.new(swift_version: '8.0')
        a.merge Podfile.new(swift_version: '8.0')
        it { expect(a.swift_version).to eq('8.0') }
    end
    context "with short" do
        a = Podfile.new(swift_version: '8.0.0')
        a.merge Podfile.new(swift_version: '8.0')
        it { expect(a.swift_version).to eq('8.0') }
    end
    context "with long" do
        a = Podfile.new(swift_version: '8.0')
        a.merge Podfile.new(swift_version: '8.0.0')
        it { expect(a.swift_version).to eq('8.0') }
    end
    context "with same width and littler" do
        a = Podfile.new(swift_version: '8.1')
        a.merge Podfile.new(swift_version: '8.0')
        it { expect(a.swift_version).to eq('8.0') }
    end
    context "with shorter and greater" do
        a = Podfile.new(swift_version: '8.0.1')
        a.merge Podfile.new(swift_version: '8.1')
        it { expect(a.swift_version).to eq('8.0.1') }
    end
end

describe 'Podfile pods merge' do
    context "with empty add more" do
        a = Podfile.new()
        b = Podfile.new()
        b.pods.push(Pod.new(name: 'b_1'))

        a.merge b
        it { expect(a.pods.length).to eq(1) }
        it { expect(a.pods[0].name).to eq('b_1') }
    end
    context "with 1 + 1" do
        a = Podfile.new()
        a.pods.push(Pod.new(name: 'a_1'))
        b = Podfile.new()
        b.pods.push(Pod.new(name: 'b_1'))

        a.merge b
        it { expect(a.pods.length).to eq(2) }
        it { expect(a.pods[0].name).to eq('a_1') }
        it { expect(a.pods[1].name).to eq('b_1') }
    end
    context "with same name" do
        a = Podfile.new()
        a.pods.push(Pod.new(name: 'a_1', version: '2'))
        b = Podfile.new()
        b.pods.push(Pod.new(name: 'a_1', version: '1'))

        a.merge b
        it { expect(a.pods.length).to eq(1) }
        it { expect(a.pods[0].name).to eq('a_1') }
        it { expect(a.pods[0].version).to eq('1') }
    end
    context "with all contains" do
        a = Podfile.new()
        a.pods.push(Pod.new(name: 'a_1', version: '2'))
        a.pods.push(Pod.new(name: 'a_2', version: '2'))
        b = Podfile.new()
        b.pods.push(Pod.new(name: 'a_1', version: '1'))

        a.merge b
        it { expect(a.pods.length).to eq(2) }
        it { expect(a.pods[0].name).to eq('a_1') }
        it { expect(a.pods[0].version).to eq('1') }
        it { expect(a.pods[1].name).to eq('a_2') }
        it { expect(a.pods[1].version).to eq('2') }
    end
end
