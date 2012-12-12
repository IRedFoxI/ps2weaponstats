#!/usr/bin/ruby

require 'rubygems'
require 'mysql2'
require '/home/pim/PS2weaponstats/dbdetails'
require 'rfutils'

$basePath = [ "/home/pim/Documents/Programming/PS2WeaponStats" ]
$fileNames = [
    "ClientItemDatasheetData.txt",
#    "FireGroups.txt",
#    "FireModes.txt",
#    "PlayerStateProperties.txt"
]
$dbPrefix = "001"

class PS2FillDB

    def initialize()
        @client = Mysql2::Client.new( :host => $dbhost, :username => $dbusername, :password => $dbpassword, :database => $dbdatabase )
    end

    def get_headers( fileName)
        headers = File.open( fileName, &:readline).split("^").drop_last
    end

end

myPS2FillDB = PS2FillDB.new

$fileNames.each do |fileName|
    myPS2FillDB.get_headers( "#{$basePath}/#{fileName}" ).each { |header| puts header }
end
