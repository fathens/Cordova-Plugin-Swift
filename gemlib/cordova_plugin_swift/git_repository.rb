require 'uri'
require 'pathname'
require 'fileutils'
require 'shellwords'

class GitRepository
    def self.lineadapter_ios(base_dir, version)
        bitbucket(base_dir, "lineadapter_ios", "version/#{version}")
    end

    def self.lineadapter_android(base_dir, version)
        bitbucket(base_dir, "lineadapter_android", "version/#{version}")
    end

    def self.bitbucket(base_dir, name, tag)
        GitRepository.new("https://bitbucket.org/fathens/#{name}.git", base_dir,
            tag: tag,
            cred: Credential.bitbucket
        )
    end

    attr_accessor :url, :base_dir, :hidden_path, :tag, :cred

    def initialize(url, base_dir = nil, tag: nil, cred: nil, username: nil, password: nil)
        @url = url
        @base_dir = base_dir || Pathname.pwd
        @hidden_path = '.repo'
        @tag = tag || "master"
        @cred = cred || Credential.build(username, password)
    end

    def dir
        @dir ||= begin
            key = File.basename(URI.parse(url).path, '.git')
            @base_dir/@hidden_path/key
        end
    end

    def remote_urls
        git_config = dir/'.git'/'config'
        if git_config.exist?
            File.readlines(git_config).map { |line|
                m = line.match /^\s*url\s*=\s*(.+)$/
                m ? m[1] : nil
            }.compact
        else
            []
        end
    end

    def git_clone
        if dir.exist?
            if remote_urls.find(@url)
                Dir.chdir(dir) {
                    system "git checkout #{tag}"
                }
                return dir
            end
            FileUtils.rm_rf(dir)
        end
        target_url = @cred&.inject_to(@url) || @url
        target_url = "-b #{tag} #{target_url}" if tag
        system "git clone #{target_url} #{dir}"
        return dir
    end
end

class Credential
    def self.bitbucket
        build(ENV['BITBUCKET_USERNAME'], ENV['BITBUCKET_PASSWORD'])
    end

    def self.build(username, password)
        if username && password
            obj = Credential.new
            obj.username = username
            obj.password = password
            obj
        else
            nil
        end
    end

    attr_accessor :username, :password

    def to_s
        [@username, @password].compact.map {|s| s.shellescape }.join(':')
    end

    def inject_to(url)
        url.sub(/^https:\/\//, "https://#{to_s}@")
    end
end
