require 'fileutils'
require 'forwardable'

class TestServer
  class TestServerDriver

    def initialize(temp_dir)
      @temp_dir = temp_dir
    end

    USER = 'user'
    PASSWORD = 'password'

    def authenticate(user, password)
      user == USER && password == PASSWORD
    end

    def file_system(user)
      TestServerFileSystem.new(@temp_dir)
    end

  end
end

class TestServer

  class TestServerFileSystem < Ftpd::DiskFileSystem

    def accessible?(ftp_path)
      return false if force_access_denied?(ftp_path)
      return true if force_file_system_error?(ftp_path)
      super
    end

    def exists?(ftp_path)
      return true if force_file_system_error?(ftp_path)
      super
    end

    def directory?(ftp_path)
      return true if force_file_system_error?(ftp_path)
      super
    end

    def delete(ftp_path)
      force_file_system_error(ftp_path)
      super
    end

    def read(ftp_path)
      force_file_system_error(ftp_path)
      super
    end

    private

    def force_file_system_error(ftp_path)
      if force_file_system_error?(ftp_path)
        raise Ftpd::FileSystemError, 'Unable to do it'
      end
    end

    def force_access_denied?(ftp_path)
      ftp_path =~ /forbidden/
    end

    def force_file_system_error?(ftp_path)
      ftp_path =~ /unable/
    end

  end
end

class TestServer

  extend Forwardable
  include FileUtils

  def initialize
    @temp_dir = Ftpd::TempDir.make
    @server = Ftpd::FtpServer.new(:data_path => @temp_dir,
                                  :port => 0)
    @templates = TestFileTemplates.new
    @server.driver = TestServerDriver.new(@temp_dir)
    @server.start 
  end

  def stop
    @server.stop
  end

  def host
    'localhost'
  end

  def add_file(path)
    full_path = temp_path(path)
    mkdir_p File.dirname(full_path)
    File.open(full_path, 'wb') do |file|
      file.puts @templates[File.basename(full_path)]
    end
  end

  def has_file?(path)
    full_path = temp_path(path)
    File.exists?(full_path)
  end

  def file_contents(path)
    full_path = temp_path(path)
    File.open(full_path, 'rb', &:read)
  end

  def user
    TestServerDriver::USER
  end

  def password
    TestServerDriver::PASSWORD
  end

  def_delegator :@server, :port

  private

  def temp_path(path)
    File.expand_path(path, @temp_dir)
  end

end
