#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'optparse'
require 'open-uri'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-v", "--version", "Target version") do |v|
    options[:version] = v
  end
end.parse!

target_release = options[:version] || "v4.0.0.3"
owner="openslide"
repo="openslide-bin"
`mkdir -p downloads artifacts`


uri = URI.parse("https://api.github.com/repos/#{owner}/#{repo}/releases")
request = Net::HTTP::Get.new(uri)
request["Accept"] = "application/vnd.github+json"
request["X-Github-Api-Version"] = "2022-11-28"

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end


releases = JSON.parse(response.body)
release = releases.find do |release|
    release["tag_name"] == target_release
end


uri = URI.parse("https://api.github.com/repos/#{owner}/#{repo}/releases/#{release["id"]}/assets")
request = Net::HTTP::Get.new(uri)
request["Accept"] = "application/vnd.github+json"
request["X-Github-Api-Version"] = "2022-11-28"


response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end



assets = JSON.parse(response.body)
asset = assets.filter do |asset| 
    asset["name"].end_with? ".tar.xz" or asset["name"].end_with? ".zip"
end.each do |asset|
    file = asset["name"]
    URI.open(asset["browser_download_url"]) do |download| 
        IO.copy_stream(download, "downloads/" + file)
    end
    if file.end_with? ".tar.xz"
        `tar -xf downloads/#{file} -C downloads`
    else
        `unzip -o downloads/#{file} -d downloads`
    end
end

["libopenslide.so", "libopenslide.dylib", "libopenslide*.dll"].each do |file|
    loc = `find downloads -name "#{file}"`.chomp
    `cp -L #{loc} artifacts`
end
