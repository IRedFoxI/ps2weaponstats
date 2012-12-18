#!/usr/bin/ruby

require 'cgi'
require 'rubygems'
require 'mysql2'
require '/home/pim/PS2weaponstats/dbdetails'
#require 'rfutils'

class PS2WeapStats

    def initialize()
        @cgi = CGI.new("html4")
        @client = Mysql2::Client.new( :host => $dbhost, :username => $dbusername, :password => $dbpassword, :database => $dbdatabase )
    end

    def add_row( row )
       tableRow = ""
       row.each { |val| tableRow << @cgi.td { "#{val}" } }
       return @cgi.tr { tableRow }
    end

    def build_sql_query( weapons, states, firemodes )
        retval = ""
        retval << "SELECT "
        retval << "WEAPON_NAME, 000_FireModes.REFIRE_TIME_MS, PROJECTILE_SPEED_OVERRIDE, 000_FireModes.RELOAD_TIME_MS, RELOAD_CHAMBER_TIME_MS, HEAD_SHOT_DAMAGE_MULTIPLIER, 000_FireModes.`#*ID`, `*PLAYER_STATE`, 000_PlayerStateProperties.MIN_CONE_OF_FIRE, MAX_CONE_OF_FIRE, COF_GROW_RATE, COF_RECOIL, COF_RECOVERY_RATE, COF_SCALAR_MOVING, COF_OVERRIDE, RECOIL_MAGNITUDE_MIN, RECOIL_MAGNITUDE_MAX, RECOIL_ANGLE_MIN, RECOIL_ANGLE_MAX, RECOIL_RECOVERY_DELAY_MS, RECOIL_RECOVERY_RATE, RECOIL_RECOVERY_ACCELERATION, RECOIL_SHOTS_AT_MIN_MAGNITUDE, RECOIL_MAX_TOTAL_MAGNITUDE, RECOIL_INCREASE, RECOIL_INCREASE_CROUCHED, RECOIL_FIRST_SHOT_MODIFIER, RECOIL_HORIZONTAL_TOLERANCE, RECOIL_HORIZONTAL_MIN, RECOIL_HORIZONTAL_MAX, TURN_MODIFIER, MOVEMENT_MODIFIER "
        retval << "FROM 000_WeaponNames, 000_ClientItemDatasheetData, 000_FireGroups, 000_FireModes, 000_PlayerStateProperties "
        retval << "WHERE ( WEAPON_NAME='#{ weapons.join( "' OR WEAPON_NAME='" ) }' ) "
        retval << "AND 000_WeaponNames.`#*ITEM_ID`=000_ClientItemDatasheetData.`#*ITEM_ID` "
        retval << "AND ( `*PLAYER_STATE`='#{ states.join( "' OR `*PLAYER_STATE`='" ) }' ) "
        retval << "AND 000_FireGroups.`#*ID`=FIRE_GROUP_ID "
        retval << "AND ( 000_FireModes.`#*ID`=#{firemodes.join( " OR 000_FireModes.`#*ID`=" ) } ) "
        retval << "AND 000_PlayerStateProperties.`#*GROUP_ID`=PLAYER_STATE_GROUP_ID"
        return retval
    end

    def add_popup_menu( text, name, values )
        retval = ""
        retval << text
        retval << @cgi.popup_menu( "NAME" => name, "VALUES" => values, "MULTIPLE" => true )
#        retval << @cgi.br
        return retval
    end

    def gen_output()

        weaponsQueryResult = @client.query( "SELECT `WEAPON_NAME` FROM `000_WeaponNames` WHERE `WEAPON_NAME`<>''" )
        weapons = weaponsQueryResult.each( :as => :array ).flatten

        selectedWeapons = @cgi.params[ 'select_weapon' ].dup
        selectedWeapons = selectedWeapons & weapons
#        weapons.unshift( "NONE" )
        if selectedWeapons.empty?
            selectedWeapons = weapons.values_at( 0 )
        end

        weaponPopupMenuData = weapons.dup
        weaponPopupMenuData.map! do |weapon|
            if selectedWeapons.include?( weapon )
                [ weapon, true ]
            else
                [ weapon ]
            end
        end

        statesQueryResult = @client.query( "SELECT DISTINCT `*PLAYER_STATE`  FROM `000_PlayerStateProperties` WHERE 1" )
        states = statesQueryResult.each( :as => :array ).flatten
        statesStrings = Hash[ "NONE" => "NONE", 0 => "Standing", 1 => "Crouching", 2 => "Moving", 3 => "Sprinting", 4 => "Jumping", 5 => "Crouched moving" ]

        selectedStates = @cgi.params[ 'select_state' ].dup
        selectedStates = selectedStates & states.map{ |i| i.to_s }
#        states.unshift( "NONE" )
        if selectedStates.empty?
            selectedStates = [ states.values_at( 0 ).to_s ]
        end

        statePopupMenuData = states.dup
        statePopupMenuData.map! do |state|
            if selectedStates.include?( state.to_s )
                [ state.to_s, statesStrings[ state ], true ]
            else
                [ state.to_s, statesStrings[ state ] ]
            end
        end

        firemodes =[ "PRIMARY_FIRE_MODE_ID", "SECONDARY_FIRE_MODE_ID" ]
        firemodesStrings = Hash[ "PRIMARY_FIRE_MODE_ID" => "From the hip", "SECONDARY_FIRE_MODE_ID" => "Down sight" ]

        selectedFireModes = @cgi.params[ 'select_firemode' ].dup
        selectedFireModes = selectedFireModes & firemodes
#        firemodes.unshift( "NONE" )
        if selectedFireModes.empty?
            selectedFireModes = firemodes.values_at( 0 )
        end

        firemodePopupMenuData = firemodes.dup
        firemodePopupMenuData.map! do |firemode|
            if selectedFireModes.include?( firemode )
                [ firemode, firemodesStrings[ firemode ], true ]
            else
                [ firemode, firemodesStrings[ firemode ] ]
            end
        end

        dataQueryResult = @client.query( build_sql_query( selectedWeapons, selectedStates, selectedFireModes ) )

        tableData = ""

        headers = dataQueryResult.fields
        tableData << add_row( headers )

        dataQueryResult.each(:as => :array) do |row|
            tableData << add_row( row )
        end

        @cgi.out {
            @cgi.html {
                @cgi.head { @cgi.title{"PlanetSide 2 Weapon Data"} } +
                @cgi.body {
                    @cgi.form{
                        @cgi.hr +
                        @cgi.h1 { "Input" } +
                        @cgi.p {
                            add_popup_menu( "Select weapon: ", "select_weapon", weaponPopupMenuData ) +
                            add_popup_menu( "Select state: ", "select_state", statePopupMenuData ) +
                            add_popup_menu( "Select aim: ", "select_firemode", firemodePopupMenuData )
                        } +
                        @cgi.submit
                    } +
                    @cgi.hr +
                    @cgi.h1 { "Output" } +
                    @cgi.table('BORDER' => '1') { tableData } +
#                    @cgi.hr +
#                    @cgi.h1 { "Parameters" } +
#                    @cgi.p { "#{@cgi.params.map{|k,v| "#{k}=#{v}"}.join( @cgi.br )}" } + "\n" +
                    @cgi.hr
                }
            }
        }

    end

end

myPS2WeapStats = PS2WeapStats.new
myPS2WeapStats.gen_output
