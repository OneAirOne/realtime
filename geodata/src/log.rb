#! /usr/bin/env ruby

require 'singleton'
require 'logger'

class Log < Logger

  include Singleton
  attr_accessor :log


  @@fileName = ""
  def self.fileName= fileName
    @@fileName = fileName
  end

  def initialize
    @fileName = @@fileName
    @log = Logger.new(@fileName,'daily')
  end

  def define_log_level(logLevel)
    if logLevel == 'DEBUG'
      @log.level = Logger::DEBUG
    elsif  logLevel == 'INFO'
      @log.level = Logger::INFO
    elsif logLevel == 'WARN'
      @log.level = Logger::WARN
    elsif logLevel == 'ERROR'
      @log.level = Logger::ERROR
    else
      @log.level = Logger::UNKNOWN
    end
  end

  def logger_formatter
    @log.formatter = proc do |severity, datetime, progname, msg|
      date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
      "[#{date_format}] #{severity} : #{msg}\n"
    end
  end

  def define_std_output(logStandardOutput)
    if logStandardOutput
      @log = Logger.new(STDOUT)
    end
  end

end
