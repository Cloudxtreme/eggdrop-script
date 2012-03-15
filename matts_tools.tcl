#Matt's Tools  v0.7.x by Matt 
set ver "0.7.2"
#what IP to bind to
set bind ""
#Your Bing App ID
set bingID ""
#Set Output Speed (0 for immed, 1 for quick, 2 for normal)
set outspeed 0
#####################
# DO NOT EDIT BELOW #
#####################
bind pub - "!bing" pub:bing:search
bind pub - "!google" pub:google:search
bind pub - "!gsearch" pub:google:search
bind pub - "!weather" pub:google:weather
bind pub - "!host" pub:host
bind pub - "!whois" pub:whois
bind pub - "!commands" pub:commands
bind pub - "!botset" pub:set
bind msg n| ".debug" msg:debug
bind pubm - "*" pub:filter 

# File Vars
set fName "wCode.db"
set lEnd "\n"
setudef flag youtube
setudef flag vimeo
setudef flag weather
setudef flag search 
proc pub:bing:search { nick uhost hand chan txt } { 
  global bind bingID 
  if { [channel get $chan search] } {
    if { [llength [split $txt]] == 0 } {
      outspd "PRIVMSG $chan :$nick, you forgot to enter a search term!"
    } else {
      regsub -all { } $txt "+" query
      set line [exec /usr/bin/wget -q -O - http://api.bing.net/xml.aspx?AppId=$bingID&Query=$query&Sources=web&web.count=1]
      if { [ regexp {\<web\:Title>(.*?)\<\/web\:Title\>.+\<web\:Url\>(.*?)\<\/web\:Url\>} $line match t u] } {
	  outspd "PRIVMSG $chan : \002Bing Top Search Result\002: $t - \00302$u\003"
      }
    }
  }
}
proc pub:google:search { nick uhost hand chan txt } { 
 global bind 
 if { [channel get $chan search] } {
    if { [llength [split $txt]] == 0 } {
      outspd "PRIVMSG $chan :$nick, you forgot to enter a search term!"
    } else {
      regsub -all { } $txt "+" query
      set line [exec /usr/bin/wget -q -O - https://ajax.googleapis.com/ajax/services/search/web?q=$query&v=1.0]
      if { [regexp {\"unescapedUrl\"\:\"(.*?)\"\,\"url\".+\"titleNoFormatting\"\:\"(.*?)\"\,\"content\"} $line match u t] } {
	outspd "PRIVMSG $chan : \002Google Top Search Result\002: $t - \00302$u\003"
      }
    }
  }
}
#Handle the call to check weather
proc pub:google:weather { nick uhost hand chan txt } {
	set code [string trim $txt]
	set test [string trim [split $txt]]
	set t1 [lindex [split $txt] 0]
	set len [llength $test]
	if {[channel get $chan weather]} { 
		if {$code == ""} {
			if {[checkCode $nick] != ""} {
				set code [checkCode $nick]
				parse:weather $code $chan 
			} else {
				outspd "PRIVMSG $chan :Please give a location or use !weather setcode <location>"
			}
		} elseif { $t1 == "setcode" } {
			if { $len >= 2 } {
				set temp [string trim [lindex [split $txt] 0]]
				#setting a code
				if {[regexp -nocase {(setcode)} $temp match]} {
					set code [string trim [lrange [split $txt] 1 $len]]
					if {[setCode $nick $code]} {
						outspd "NOTICE $nick :Set your default location to $code!"
					} else {
						outspd "NOTICE $nick :Unable to set your default location!"
					}
					return
				}
			} else { 
				outspd "PRIVMSG $chan :Please use !weather setcode location"
			}
		} else  {

			parse:weather $code $chan
		}
	}
}
proc pub:host { nick uhost hand chan txt } {
	set type [string trim [lindex [split $txt] 0]]
	set host [string trim [lindex [split $txt] 1]]
	set len [string trim [llength [split $txt]]]
	set dns ""
	if {$host != ""} {
		if { $len == 3 } {
			set dns [string trim [lindex [split $txt] 2]]
		}
		if {[regexp -nocase {^(a|4|ipv4)$} $type]} {
			if { $dns != "" } {
				set out [exec host -tA $host $dns]
				outspd "PRIVMSG $chan :Querying $dns for A records on $host"
			} else {
				set out [exec host -tA $host] 
			}
			set addrs [split $out \n]
			foreach addr $addrs {
				if [regexp {(.*?) has address (.*?)$} $addr match rHost output] {
					outspd "PRIVMSG $chan :$rHost => $output"
				}
			}
		} elseif {[regexp -nocase {^(aaaa|6|ipv6)$} $type]} { 
			if {$dns != ""} { 
				set out [exec host -tAAAA $host $dns]
				outspd "PRIVMSG $chan :Querying $dns for AAAA records on $host"				
			} else { 
				set out [exec host -tAAAA $host] 
			}
			set addrs [split $out \n]
			foreach addr $addrs {
				if [regexp {(.*) has IPv6 address (.*)} $addr match rHost output] {
					outspd "PRIVMSG $chan :$rHost => $output" 
				}
			}
		} elseif {[regexp -nocase {^(mx)$} $type]} {
			if { $dns != "" } {
				set out [exec host -tMX $host $dns]
				outspd "PRIVMSG $chan :Querying $dns for MX records on $host"
			} else {
				set out [exec host -tMX $host]
			}
			set addrs [split $out \n]
			foreach addr $addrs {
				if [regexp {(.*) mail is handled by (.*) (.*)} $addr match rHost pri output] {
					outspd "PRIVMSG $chan :$rHost => $output"
				}
			}
		} elseif {[regexp -nocase {^(txt)$} $type]} {
			if { $dns != "" } {
				set out [exec host -tTXT $host $dns]
				outspd "PRIVMSG $chan :Querying $dns for TXT records on $host"
			} else {
				set out [exec host -tTXT $host] 
			}
			set addrs [split $out \n]
			foreach addr $addrs {
				if [regexp {(.*) descriptive text (.*)} $addr match rHost output] {
					outspd "PRIVMSG $chan :$rHost => $output"
				}
			}
		} elseif {[regexp -nocase {^(ns)$} $type]} {
			if { $dns != "" } {
				set out [exec host -tNS $host $dns]
				outspd "PRIVMSG $chan :Querying $dns for NS records on $host"
			} else {
				set out [exec host -tNS $host] 
			}
			set addrs [split $out \n]
			foreach addr $addrs {
				if [regexp {(.*) name server (.*)} $addr match rHost output] {
					outspd "PRIVMSG $chan :$rHost => $output"
				}
			}
		} elseif {[regexp -nocase {^(ptr)$} $type]} {
			if { $dns != "" } {
				set out [exec host -tPTR $host $dns]
				outspd "PRIVMSG $chan :Querying $dns for NS records on $host"
			} else {
				set out [exec host -tPTR $host]
			}
			set addrs [split $out \n]
			foreach addr $addrs {
			    if {[regexp {domain name pointer (.*)} $addr output]} {
					outspd "PRIVMSG $chan :$host => $output"
				}
			}
		} elseif {[regexp -nocase {^(all|any|)$} $type]} {
			if { $dns != "" } { 
				set out [exec host $host $dns]
				outspd "PRIVMSG $chan :Querying $dns for ANY records for $host"
			} else {
				set out [exec host $host]
			}
			set lines [split $out \n]
			outspd "PRIVMSG $chan :Records for $host"
			foreach line $lines {
				if {[regexp {(.*) has address (.*)} $line match rHost output]} {
					set rec [regexp {(.*) has address (.*)} $line match rHost output]
					outspd "PRIVMSG $chan :A => $output"
				} elseif {[regexp {(.*) has IPv6 address (.*)} $line match rHost output]} {
					set rec [regexp {(.*) has IPv6 address (.*)} $line match rHost output]
					outspd "PRIVMSG $chan :AAAA => $output"
				} elseif {[regexp {(.*) mail is handled by (.*) (.*)} $line match rHost pri output]} {
					set rec [regexp {(.*) mail is handled by (.*) (.*)} $line match rHost pri output]
					outspd "PRIVMSG $chan :MX => $pri -> $output"
				} elseif {[regexp {(.*) name server (.*)} $line match rHost output]} {
					set rec [regexp {(.*) name server (.*)} $line match rHost output]
					outspd "PRIVMSG $chan :NS => $output"
				} 
			}
		}
	}
}
proc pub:whois { nick uhost hand chan txt } {
	set domain [lindex [split $txt] 0] 
	if { $domain != "" } {
		set output [exec whois $domain]
		set lines [split $output \n]
		foreach line $lines { 
			if [regexp -nocase {(created on|expires on|record last updated on)} $line] {
				outspd "PRIVMSG $chan :$line"
			}
		}

	}
}
proc pub:filter { nick uhost hand chan txt } {
	if {[regexp -nocase {https?:\/\/(?:www.)?youtube\.com\/watch\?(.*)v=([A-Za-z0-9_\-]+)} $txt match junk vid]} {
		if {[channel get $chan youtube]} { 	
			parse:youtube $vid $chan
		}
		return
	} elseif {[regexp -nocase {https?:\/\/(?:www.)?vimeo\.com\/(?:.*#|.*/channels/)?([0-9]+)} $txt match vid]} {
		if {[channel get $chan vimeo]} {
			parse:vimeo $vid $chan 	
		}
		return
	}
}
# Command list
proc pub:commands { nick uhost hand chan txt } {
	outspd "PRIVMSG $chan :---------- Commands ----------"
	outspd "PRIVMSG $chan : You \002may\002 need to enable commands with !botset!"
	outspd "PRIVMSG $chan :!weather <zip|major city|airport code|city state> -- Weather Lookup"
	outspd "PRIVMSG $chan :!host <A|AAAA|PTR|CNAME|MX|NS> <host/IP> ----------- Hostname Lookup"
	outspd "PRIVMSG $chan :!botset <option|help> <on|off> --------------------- Bot's settings for chan" 
	outspd "PRIVMSG $chan :---------- Commands ----------"
}
#!botset
proc pub:set { nick uhost hand chan txt } {
	set option [string tolower [string trim [lindex [split $txt] 0]]]
	set setting [string tolower [string trim [lindex [split $txt] 1]]]
	if { $option == "help" } {
		outspd "PRIVMSG $chan :Options: youtube vimeo search weather"
	} elseif { $setting == "" } {
		return 
	} else {
		if {[isop $nick $chan]} {
			if {[regexp -nocase {^(youtube|vimeo|search|weather)$} $option match]} {
				if {[regexp -nocase {^(on|off)$} $setting match]} {
					if { $setting == "on" } {
						channel set $chan +$option
						outspd "PRIVMSG $chan :\002Enabled $option\002 on this channel!"
					} else { 
						channel set $chan -$option
						outspd "PRIVMSG $chan :\002Disabled $option\002 on this channel!"
					}
				}
			}
		}
	}		
}
#Parse Data
proc parse:weather { txt chan } { 
	global bind
	set baseurl "http://www.google.com/ig"
	#Replace Spaces with a "+" 
	regsub -all {( )} $txt "+" location
	regsub -all {,} $location "" location
	#Setup the URL
	set url "$baseurl/api?weather=$location";
	#Get the URL
	set out [exec /usr/bin/wget -q -O - --bind-address=$bind $url]
	#Parse the data using Regexp
	if {[regexp {^(.*?)\<city data\=\"(.*?)\"\/>(.*?)\<condition data\=\"(.*?)\"\/>\<temp\_f data\=\"(.*?)\"\/\>\<temp\_c data\=\"(.*?)\"\/\>\<humidity data\=\"(.*?)\"\/\>(.*?)\<wind\_condition data\=\"(.*?)\"\/\>} $out match j1 loc j2 cond tempF tempC humid j3 wind]} {
		set temp "$tempF F ($tempC C)"
		outspd "PRIVMSG $chan :Current Weather for $loc : Conditions: $cond - Temp: $temp - $wind - $humid"
	} else { 
		outspd "PRIVMSG $chan :Failed to parse the weather data (Likely invalid location)"
	}
}
proc parse:youtube { vid chan } {
	global bind botnick
	set baseurl "http://gdata.youtube.com/feeds/api/videos"
	set url "$baseurl/$vid"
	set out [exec /usr/bin/wget -q -O - --bind-address=$bind $url]
	if {[regexp {(.*?)\<title type\=\'text\'\>(.*?)\<\/title\>\<content type\=\'text\'\>(.*?)\<\/content\>.+} $out match j1 title desc]} {
		outspd "PRIVMSG $chan :\002\0034Youtube Title\003\002: \0032$title\003 - \002\0034Desc\002\003 \0032$desc\003 "
	}
}
proc parse:vimeo { vid chan } { 
	global bind
	set baseurl "http://vimeo.com/api/v2/video"
	set url "$baseurl/$vid.xml"
	set out [exec /usr/bin/wget -q -O - --bind-address=$bind $url]
	if {[regexp -nocase {(.*?)<title>(.*?)</title><description>(.*?)</description>(.*?)<stats_number_of_likes>(.*?)</stats_number_of_likes><stats_number_of_plays>(.*?)</stats_number_of_plays>} $out match j1 title desc j2 likes plays]} {
		outspd "PRIVMSG $chan :\002Vimeo Title\002: \00302$title\003"
	}
}

#Debug functions
proc msg:debug { nick uhost hand txt } {
	set option [string tolower [string trim [lindex [split $txt] 0]]]
	if { $option == "wfile" } {
		set out [exec cat wCode.db]
		set lines [split $out "\n"]
		set i 0
		outspd "PRIVMSG $nick :\002DEBUG:\002 Reading wCode.db..."
		foreach line $lines {
			incr i 
			set lne [string trim $line]
			if {$lne != ""} {
				outspd "PRIVMSG $nick :\002DEBUG:\002 $i - $line"
			}
		}
		outspd "PRIVMSG $nick :\002DEBUG:\002 ...EOF!"
	} elseif { $option == "help" } {
		outspd "PRIVMSG $nick :Debug options: wFile"
	}
}
# Weather File Management 
proc checkCode { nick } {
	global fName lEnd 
	set fd [open $fName "r"]
	set fdata [read $fd]
	set data [split $fdata $lEnd]
	close $fd
	foreach line $data { 
		set n [string trim [lindex [split $line ":"] 0]]
		set code [string trim [lindex [split $line ":"] 1]]
		if {$n == $nick} {
			if {$code != ""} {
				return $code
			} else {
				return ""
			}
		}
	}
	return ""
}
proc setCode { nick code } {
	global fName lEnd 
	set fd [open $fName "r"]
	set fdata [read $fd]
	set data [split $fdata "\n"]
	set new "$fName.new"
	set bak "$fName.bak"
	close $fd
	
	if {$code != ""} {		
		set i 0
		foreach line $data {
			set i [expr $i + 1]		
			set n [string trim [lindex [split $line ":"] 0]]
			if {$n == $nick} {
				set num [expr $i - 1]
				set nData [lreplace $data $num $num "$nick:$code"]
				set fdn [open $new "w+"]
				foreach line $nData {
					puts -nonewline $fdn "$line\n"
				}
				close $fdn
				mvFile $fName $new $bak
				return 1
			}
		}
		set fd [open $fName "a+"]
		puts -nonewline $fd "\n$nick:$code"
		close $fd
		return 1
	} else { 
		return 0
	}
}
#Move Files
proc mvFile { old new backup } {
	file copy -force $old $backup
	file rename -force $new $old
}
# Determine how to output the data
proc outspd { txt } {
	global outspeed
	if { $outspeed == 0 } { 
		putnow $txt
	} elseif { $outspeed == 1 } {
		putquick $txt
	} elseif { $outspeed == 2 } {
		putserv $txt
	}
}
if {![file exists $fName]} {
	exec touch $fName
}
putlog "Matt's Tools V$ver loaded"