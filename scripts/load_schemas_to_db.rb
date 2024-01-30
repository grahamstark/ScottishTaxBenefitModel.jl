#!/usr/bin/ruby
#
# bits and pieces to load converted allissue schema files into a postgres database
# you need to convert the .rtf files to ascii first. Do this with:
# soffice --headless --convert-to txt *.rtf
#

require 'ukds_schema_utils'
require 'utils'
load 'conversion_constants.rb'


# datasets = [  "frs", 'lcf', 'shs' ]
# years = [2016,2017]
# datasets = [  "lcf" ]
# years = 2009..2020


#
# parse all .tab files in a directory and load to ukds.dictionaries schema
#
def parseFiles( targetdir, dataset, year )
        be = BlankEdit.new()
        Dir["#{targetdir}/*.txt"].each{
                |fullFileName|
                fileName = File.basename( fullFileName )
                puts "on file #{fileName}"
                tableName = extractTableName( dataset, fileName )
                if tableName then
                        puts "datset #{dataset}; Parsing |#{fileName}| tablename=|#{tableName}|"
                        readOneRTF( dataset, year, fullFileName, tableName, be )
                end
        }
end

#
# lcf filenames are all over the place, so this is just a manually edited version
# with filename,tablename,year fields /mnt/data/lcf/txts
#
def hacky_lcf_parse( filename )
        be = BlankEdit.new()
        f = File.new( filename, 'r' )
        dataset = "lcf"
        f.each_line{
                |line|
                bits = line.split( " ")
                puts bits
                year = bits[2].to_i
                puts year
                tableName = bits[1]
                fileName = "#{UKDS_DATA_DIR}/#{dataset}/#{bits[0]}"
                puts "parsing #{fileName}"
                readOneRTF( dataset, year, fileName, tableName, be )
        }
end

def extractTableName( dataset, filename )
        if dataset == 'lcf' && filename =~ /2016_17_+(.*)_ukanon_ukda_data_dictionary/
                return $1
        elsif dataset == 'lcf' && filename =~ /(.*)_ukanon_.*_ukda_data_dictionary/
                return $1
        elsif dataset == 'shs' && filename =~ /shs[0-9]{4}_(.*)_public_ukda_data_dictionary/
                return $1
        elsif dataset == 'frs' && filename =~ /(.*)_ukda_data_dictionary/
                return $1
        elsif dataset == 'was'

        elsif dataset == 'shs' && filename =~ /shs2017_td_(.*)_public_ukda_data_dictionary/
                return $1
        elsif dataset == 'scjs' 
                if filename =~ /scjs1920_nvf-main_y4_eul-safeguarded_[0-9]+_(.*)_ukda_data_dictionary/
                        return $1
                elseif filename =~ /.*cyber.*/
                        return 'cyber'
                else
                        return 'main'
                end
        end
end

def yeardir( dataset, year )
        if dataset == 'frs'
                return "#{year}"
        else
                i = year-2000
                j = i+1
                return "#{i}#{j}"
        end
end



# efs dvhh_ukanon_2017-18_ukda_data_dictionary.txt => dvhh
# shs shs2017_td_home_school_public_ukda_data_dictionary.txt => td_home_school
# frs govpay_ukda_data_dictionary.txt => govpay

datasets = [  "shs" ]
years = 2019..2021
datasets = [  "scjs" ]
years = 2017..2019

datasets.each{
        |dataset|
        years.each{
                |year|
                yd = yeardir( dataset, year )
                targetdir = "#{UKDS_DATA_DIR}/#{dataset}/#{yd}/mrdoc/allissue/"
                puts "opening dir #{targetdir}"
                parseFiles( targetdir, dataset, year )
        }
}
