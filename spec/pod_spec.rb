require "spec_helper"

describe 'Pod version merge' do
    context "with upper" do
        a = Pod.new(version: '8.0')
        a.merge Pod.new(version: '9.0')
        it { expect(a.version).to eq('8.0') }
    end
    context "with under" do
        a = Pod.new(version: '8.0')
        a.merge Pod.new(version: '7.0')
        it { expect(a.version).to eq('7.0') }
    end
    context "with same" do
        a = Pod.new(version: '8.0')
        a.merge Pod.new(version: '8.0')
        it { expect(a.version).to eq('8.0') }
    end
    context "with short" do
        a = Pod.new(version: '8.0.0')
        a.merge Pod.new(version: '8.0')
        it { expect(a.version).to eq('8.0') }
    end
    context "with long" do
        a = Pod.new(version: '8.0')
        a.merge Pod.new(version: '8.0.0')
        it { expect(a.version).to eq('8.0') }
    end
    context "with same width and littler" do
        a = Pod.new(version: '8.1')
        a.merge Pod.new(version: '8.0')
        it { expect(a.version).to eq('8.0') }
    end
    context "with shorter and greater" do
        a = Pod.new(version: '8.0.1')
        a.merge Pod.new(version: '8.1')
        it { expect(a.version).to eq('8.0.1') }
    end
end

describe 'Pod source merge' do
    context "when git to path" do
        a = Pod.new(git: 's_git')
        b = Pod.new(path: 's_path')
        a.merge b
        it { expect(a.git).to be_nil }
        it { expect(a.path).to eq('s_path') }
    end
    context "when path to podspec" do
        a = Pod.new(path: 's_path')
        b = Pod.new(podspec: 's_spec')
        a.merge b
        it { expect(a.path).to be_nil }
        it { expect(a.podspec).to eq('s_spec') }
    end
    context "when podspec to git" do
        a = Pod.new(podspec: 's_spec')
        b = Pod.new(git: 's_git')
        a.merge b
        it { expect(a.git).to be_nil }
        it { expect(a.podspec).to eq('s_spec') }
    end
    context "when git to podspec" do
        a = Pod.new(git: 's_git')
        b = Pod.new(podspec: 's_spec')
        a.merge b
        it { expect(a.git).to be_nil }
        it { expect(a.podspec).to eq('s_spec') }
    end
    context "when podspec to path" do
        a = Pod.new(podspec: 's_spec')
        b = Pod.new(path: 's_path')
        a.merge b
        it { expect(a.path).to be_nil }
        it { expect(a.podspec).to eq('s_spec') }
    end
    context "when path to git" do
        a = Pod.new(path: 's_path')
        b = Pod.new(git: 's_git')
        a.merge b
        it { expect(a.git).to be_nil }
        it { expect(a.path).to eq('s_path') }
    end
end

describe 'Pod merge git disappear' do
    context "when git to path" do
        a = Pod.new(git: 's_git', branch: 'git_branch', tag: 'git_tag', commit: 'git_commit')
        b = Pod.new(path: 's_path')
        a.merge b
        it { expect(a.git).to be_nil }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to be_nil }
        it { expect(a.commit).to be_nil }
        it { expect(a.path).to eq('s_path') }
    end
    context "when git to podspec" do
        a = Pod.new(git: 's_git', branch: 'git_branch', tag: 'git_tag', commit: 'git_commit')
        b = Pod.new(podspec: 's_spec')
        a.merge b
        it { expect(a.git).to be_nil }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to be_nil }
        it { expect(a.commit).to be_nil }
        it { expect(a.podspec).to eq('s_spec') }
    end
end

describe 'Pod merge git tags' do
    context "when branch to tag" do
        a = Pod.new(git: 's_git', branch: 'git_branch')
        b = Pod.new(git: 's_git', tag: 'git_tag')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to eq('git_tag') }
        it { expect(a.commit).to be_nil }
    end
    context "when tag to commit" do
        a = Pod.new(git: 's_git', tag: 'git_tag')
        b = Pod.new(git: 's_git', commit: 'git_commit')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to be_nil }
        it { expect(a.commit).to eq('git_commit') }
    end
    context "when commit to branch" do
        a = Pod.new(git: 's_git', commit: 'git_commit')
        b = Pod.new(git: 's_git', branch: 'git_branch')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to be_nil }
        it { expect(a.commit).to eq('git_commit') }
    end
    context "when branch to commit" do
        a = Pod.new(git: 's_git', branch: 'git_branch')
        b = Pod.new(git: 's_git', commit: 'git_commit')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to be_nil }
        it { expect(a.commit).to eq('git_commit') }
    end
    context "when commit to tag" do
        a = Pod.new(git: 's_git', commit: 'git_commit')
        b = Pod.new(git: 's_git', tag: 'git_tag')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to be_nil }
        it { expect(a.commit).to eq('git_commit') }
    end
    context "when tag to branch" do
        a = Pod.new(git: 's_git', tag: 'git_tag')
        b = Pod.new(git: 's_git', branch: 'git_branch')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to eq('git_tag') }
        it { expect(a.commit).to be_nil }
    end
end

describe 'Pod merge git different tags' do
    context "with branch" do
        a = Pod.new(git: 's_git', branch: 'branch_a')
        b = Pod.new(git: 's_git', branch: 'branch_b')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to eq('branch_a') }
        it { expect(a.tag).to be_nil }
        it { expect(a.commit).to be_nil }
    end
    context "with tag" do
        a = Pod.new(git: 's_git', tag: 'tag_a')
        b = Pod.new(git: 's_git', tag: 'tag_b')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to eq('tag_a') }
        it { expect(a.commit).to be_nil }
    end
    context "with commit" do
        a = Pod.new(git: 's_git', commit: 'commit_a')
        b = Pod.new(git: 's_git', commit: 'commit_b')
        a.merge b
        it { expect(a.git).to eq('s_git') }
        it { expect(a.branch).to be_nil }
        it { expect(a.tag).to be_nil }
        it { expect(a.commit).to eq('commit_a') }
    end
end
