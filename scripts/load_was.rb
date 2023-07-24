#!/usr/bin/ruby
#
# Load UKDS schemas into my database.
# Jammed on WAS version because I can't be arsed adding to the general version.
#

require 'ukds_schema_utils'
require 'utils'
load 'conversion_constants.rb'

#
# parse all .tab files in a directory and load to ukds.dictionaries schema
#
def parseFiles( targetdir, dataset )
        be = BlankEdit.new()
        Dir["#{targetdir}/*.txt"].each{
                |fullFileName|
                fileName = File.basename( fullFileName )
                if fileName =~ /was_.*_([1-7])_(.*?)_.*/
                    wave = $1.to_i
                    year = (wave * 2) + 2006 # wave 1 = 2008, 2=2010 etc.
                    tableName = $2
                    puts "datset #{dataset}; Parsing |#{fileName}| tablename=|#{tableName}| year=#{year} wave #{wave}"
                    readOneRTF( dataset, year, fullFileName, tableName, be )
                end # matching
        } # each
end

dataset="was"
targetdir = "/mnt/data/was/UKDA-7215-tab/mrdoc/rtf"
puts "opening dir #{targetdir}"
parseFiles( targetdir, dataset )