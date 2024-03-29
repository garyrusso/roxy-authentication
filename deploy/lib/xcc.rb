###############################################################################
# Copyright 2012 MarkLogic Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################
require 'uri'
require 'net/http'
require 'RoxyHttp'
require 'MLClient'

RUBY_XCC_VERSION = "0.9a"
XCC_VERSION = "5.0-2"
LOCALE = "en_US"

module Net
  class HTTPGenericRequest
    def set_path(path)
      @path = path
    end

    def write_header(sock, ver, path)
      buf = "#{@method} #{path} XDBC/1.0\r\n"
      each_capitalized do |k,v|
        buf << "#{k}: #{v}\r\n"
      end
      buf << "\r\n"
      sock.write buf
    end
  end

  class << HTTPResponse
    def read_status_line(sock)
      str = sock.readline
      m = /\A(?:HTTP|XDBC)(?:\/(\d+\.\d+))?\s+(\d\d\d)\s*(.*)\z/in.match(str) or
        raise HTTPBadResponse, "wrong status line: #{str.dump}"
      m.captures
  	end
  end

  # Turns on keep-alive for xcc in Ruby 1.8.x
  class HTTP
    def keep_alive?(req, res)
      true
    end
  end

  # Turns on keep-alive for xcc in Ruby 1.9.x
  module HTTPHeader
    def connection_keep_alive?
      true
    end
  end
end

module Roxy
  class ContentCapability
    READ = "R"
    INSERT = "I"
    UPDATE = "U"
    EXECUTE = "E"
    ER = ["E", "R"]
    RU = ["R", "U"]
  end

  class Xcc < MLClient

    attr_reader :hostname, :port

    IGNORE_EXTENSIONS = ['..', '.', '.svn', '.git', '.ds_store', 'thumbs.db']

    def initialize(options)
      super(options)
      @hostname = options[:xcc_server]
      @port = options[:xcc_port]
      @http = Roxy::Http.new :logger => logger
      @request = {}
      @gmt_offset = Time.now.gmt_offset
    end

    def xcc_query(options)
      headers = {}

      params = {
        :xquery => options[:query],
        :locale => LOCALE,
        :tzoffset => "-18000",
        :dbname => options[:db]
      }

      r = go "http://#{options[:host]}:#{options[:port]}/eval", "post", headers, params
    end

    def load_files(path, options = {})
      if File.exists?(path)
        headers = {
          'Content-Type' => "text/xml",
          'Accept' => "text/html, text/xml, image/gif, image/jpeg, application/vnd.marklogic.sequence, application/vnd.marklogic.document, */*"
        }

        data = get_files(path, options)
        size = data.size

        batch_commit = options[:batch_commit] == true
        logger.debug "Using Batch commit: #{batch_commit}"
        data.each_with_index do |file_uri, i|
          commit = ((false == batch_commit) || (i >= (size - 1)))

          target_uri = build_target_uri(file_uri, options)
          url = build_load_uri(target_uri, options, commit)
          logger.debug "loading: #{file_uri} => #{target_uri}"

          r = go url, "put", headers, nil, prep_body(file_uri, commit)
          logger.error(r.body) unless r.code.to_i == 200
        end

        return data.length
      else
        logger.error "#{path} does not exist"
      end
      0
    end

    def load_buffer(uri, buffer, options)
      headers = {
        'Content-Type' => "text/xml",
        'Accept' => "text/html, text/xml, image/gif, image/jpeg, application/vnd.marklogic.sequence, application/vnd.marklogic.document, */*"
      }

      commit = options[:commit]
      commit = true if (commit == nil)
      target_uri = build_target_uri(uri, options)
      url = build_load_uri(target_uri, options, commit)
      logger.debug "loading: #{uri} => #{target_uri}"

      r = go url, "put", headers, nil, prep_buffer(buffer, true)
      logger.error(r.body) unless r.code.to_i == 200

      1
    end

    private

    def go(url, verb, headers = {}, params = nil, body = nil)
      headers['User-Agent'] = "Roxy RubyXCC/#{RUBY_XCC_VERSION}  MarkXDBC/#{XCC_VERSION}"
      super(url, verb, headers, params, body)
    end

    def get_files(path, options = {}, data = [])
      if File.directory?(path)
        Dir.foreach(path) do |entry|
          next if IGNORE_EXTENSIONS.include?(entry.downcase)
          full_path = File.join(path, entry)
          skip = false

          options[:ignore_list].each do |ignore|
            if full_path.match(ignore)
              skip = true
              break
            end
          end if options[:ignore_list]

          next if skip == true

          if File.directory?(full_path)
            get_files(full_path, options, data)
          else
            data << full_path
          end
        end
      else
        data = [path]
      end
      data
    end

    def build_target_uri(file_uri, options)
      target_uri = file_uri.sub(options[:remove_prefix] || "", "")
      if options[:add_prefix]
        prefix = options[:add_prefix].chomp("/")
        target_uri = prefix + target_uri
      end
      target_uri
    end

    def build_load_uri(target_uri, options, commit)
      url = "http://#{@hostname}:#{@port}/insert?"

      url << "uri=#{url_encode(target_uri)}"

      url << "&locale=#{options[:locale]}" if options[:locale]

      url << "&lang=#{options[:language]}" if options[:language]

      url << "&defaultns=#{options[:namespace]}" if options[:namespace]

      url << "&quality=#{options[:quality]}" if options[:quality]


      url << "&repair=none" if options[:repairlevel] == "none"
      url << "&repair=full" if options[:repairlevel] == "full"

      url << "&format=xml" if options[:format] == "xml" || target_uri.match(/.*\.(xml|html)$/)
      url << "&format=text" if options[:format] == "text"
      url << "&format=binary" if options[:format] == "binary"

      options[:forests].each do |forest|
        url << "&placeKey=#{forest}"
      end if options[:forests]

      options[:collections].each do |collection|
        url << "&coll=#{collection}"
      end if options[:collections]

      options[:permissions].each do |perm|
        url << "&perm=#{perm[:capability]}#{perm[:role]}"
      end if (options[:permissions])

      url << "&tzoffset=#{@gmt_offset}"

      url << "&dbname=#{options[:db]}" if options[:db]

      url << "&nocommit" if false == commit

      url
    end

    def prep_body(path, commit)
      prep_buffer(File.open(path, 'rb') { |f| f.read }, commit)
    end

    def prep_buffer(buffer, commit)
      #flag that ML server is expecting
      flag = commit ? 10 : 20

      # oh so special format that xcc needs to send
      body = "0#{buffer.length}\r\n#{buffer}#{flag}\r\n"
    end

  end
end