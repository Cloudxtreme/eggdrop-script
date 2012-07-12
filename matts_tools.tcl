#Matt's Tools  v1.1.x by Matt 
set ver "1.1"
#what IP to bind to
set bind ""
#Your Bing App ID (bing functions will not work with out this!)
set bingID ""
#Set Output Speed (0 for immed, 1 for quick, 2 for normal)
set outspeed 0
#####################
# DO NOT EDIT BELOW #
#####################
set ballResponse "Maybe|Ask me tomorrow|The stars align in your favor|Chances are good|Eh, not feeling it, sorry|The outlook is grim|Better luck next time|No.|Ask another question|Yes.|I'm not sure" 
bind pub - "!8ball" pub:game:8ball
bind pub - "!bing" pub:bing:search
bind pub - "!google" pub:google:search
bind pub - "!gsearch" pub:google:search
bind pub - "!weather" pub:google:weather
bind pub - "!host" pub:host
bind pub - "!whois" pub:whois
bind pub - "!whois2" pub:rawwhois
bind pub - "!commands" pub:commands
bind pub - "!botset" pub:set
bind pub - "!ud" pub:urban
bind pub - "!urban" pub:urban
bind msg n| ".debug" msg:debug
bind pubm - "*" pub:filter 



# File Vars
set fName "wCode.db"
set lEnd "\n"

# Custom channel Flags 
setudef flag youtube
setudef flag vimeo
setudef flag weather
setudef flag search 
setudef flag games
setudef flag regex

array set eschtml_map {
	lt <   gt >   amp &   quot \"   copy \xa9
	reg \xae   ob \x7b   cb \x7d   nbsp \xa0
	nbsp \xa0 iexcl \xa1 cent \xa2 pound \xa3 curren \xa4
	yen \xa5 brvbar \xa6 sect \xa7 uml \xa8 copy \xa9
	ordf \xaa laquo \xab not \xac shy \xad reg \xae
	hibar \xaf deg \xb0 plusmn \xb1 sup2 \xb2 sup3 \xb3
	acute \xb4 micro \xb5 para \xb6 middot \xb7 cedil \xb8
	sup1 \xb9 ordm \xba raquo \xbb frac14 \xbc frac12 \xbd
	frac34 \xbe iquest \xbf Agrave \xc0 Aacute \xc1 Acirc \xc2
	Atilde \xc3 Auml \xc4 Aring \xc5 AElig \xc6 Ccedil \xc7
	Egrave \xc8 Eacute \xc9 Ecirc \xca Euml \xcb Igrave \xcc
	Iacute \xcd Icirc \xce Iuml \xcf ETH \xd0 Ntilde \xd1
	Ograve \xd2 Oacute \xd3 Ocirc \xd4 Otilde \xd5 Ouml \xd6
	times \xd7 Oslash \xd8 Ugrave \xd9 Uacute \xda Ucirc \xdb
	Uuml \xdc Yacute \xdd THORN \xde szlig \xdf agrave \xe0
	aacute \xe1 acirc \xe2 atilde \xe3 auml \xe4 aring \xe5
	aelig \xe6 ccedil \xe7 egrave \xe8 eacute \xe9 ecirc \xea
	euml \xeb igrave \xec iacute \xed icirc \xee iuml \xef
	eth \xf0 ntilde \xf1 ograve \xf2 oacute \xf3 ocirc \xf4
	otilde \xf5 ouml \xf6 divide \xf7 oslash \xf8 ugrave \xf9
	uacute \xfa ucirc \xfb uuml \xfc yacute \xfd thorn \xfe
	yuml \xff
}

proc pub:game:8ball { nick uhost hand chan question } {
  global ballResponse
  if { [channel get $chan games] } {
    set answers [split $ballResponse "|"]
    set len [expr {int([llength $answers] - 1)}]
    set rand [expr {int(rand()*$len)}] 
    set answer [lindex $answers $rand]
    outspd "PRIVMSG $chan :$answer"
  }
}
proc pub:bing:search { nick uhost hand chan txt } { 
  global bind bingID 
  if { [channel get $chan search] } {
    if { $bingID == "" } { 
      outspd "PRIVMSG $chan : Please contact the owner of the bot and have them set up a bing dev account. \00302http://www.bing.com/toolbox/bingdeveloper/\003"
    } elseif { [llength [split $txt]] == 0 } {
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
	  outspd "PRIVMSG $chan :$nick please use !whois2"
}
proc pub:rawwhois { nick uhost hand chan txt } { 
	set domain [lindex [split $txt] 0]
	if { $domain != "" } {
	      outspd "PRIVMSG $chan :Looking up info on $domain..."
	      set output [exec whois -rFH $domain]
	      set lines [split $output \n]
	      foreach line $lines {
		  if {[regexp -nocase {registar\: (.*?)$} $line match registar]} {
		    outspd "PRIVMSG $chan :Registar => $registar"
		  } elseif {[regexp -nocase {creation date\: (.*?)$} $line match created]} {
		      outspd "PRIVMSG $chan :Created On: $created"
		  } elseif {[regexp -nocase {updated date\: (.*?)$} $line match up]} { 
		      outspd "PRIVMSG $chan :Last Updated: $up"
		  } elseif {[regexp -nocase {expiration date\: (.*?)$} $line match expire]} {
		      outspd "PRIVMSG $chan :Expires on: $expire"
		  }
	      }
	}
}
proc pub:filter { nick uhost hand chan txt } {
	set channel $chan
	#Youtube Filters
	#old regexp https?:\/\/(?:www\.)?youtube\.com\/watch\?(.*)v=([A-Za-z0-9_\-]+)
	if {[regexp -nocase {https?\:\/\/(?:www)?\.youtube\.com\/watch\?v=([\w-]{11})} $txt match vid]} {
		if {[channel get $chan youtube]} { 	
			parse:youtube $vid $chan
		}
		return
	} elseif {[regexp -nocase {https?:\/\/youtu\.be\/([\w-]{11})} $txt match vid]} {
		if {[channel get $chan youtube]} { 	
			parse:youtube $vid $chan
		}
		return
	#Vimeo Filters
	} elseif {[regexp -nocase {https?:\/\/(?:www.)?vimeo\.com\/(?:.*#|.*/channels/)?([0-9]+)} $txt match vid]} {
		if {[channel get $chan vimeo]} {
			parse:vimeo $vid $chan 	
		}
		return
	#Regex Filters
	} elseif {[channel get $channel regex]} {
		if  {[regexp -nocase {^(sed|regex) (.*)$} $txt match j1 exp]} {
			set msg [search:lastmsg $channel $nick]
			set exp [string trim $exp]
			if {$msg == "Result not found"} {
				outspd "PRIVMSG $chan :$nick, I couldn't find your last messsage!"
			} elseif { $msg == "File not found" } {
				outspd "PRIVMSG $chan :$nick, there seems to be a problem finding the file!"
			} else {
				set out [exec echo "$msg" | sed "$exp"]
				outspd "PRIVMSG $chan :$out"
			}
		} else {
			add:lastmsg $chan $nick $txt
		}
	}
}
# Command list
proc pub:commands { nick uhost hand chan txt } {
	outspd "PRIVMSG $chan :---------- Commands ----------"
	outspd "PRIVMSG $chan : You \002may\002 need to enable commands with !botset!"
	outspd "PRIVMSG $chan :!8ball <question> ---------------------------------- 8ball game"
	outspd "PRIVMSG $chan :!bing <question> ----------------------------------- Bing Search"
	outspd "PRIVMSG $chan :!google <question> --------------------------------- Google Search"
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
		outspd "PRIVMSG $chan :Options: youtube vimeo search weather games regex"
	} elseif { $setting == "" } {
		return 
	} else {
		if {[isop $nick $chan]} {
			if {[regexp -nocase {^(youtube|vimeo|search|weather|games|regex)$} $option match]} {
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
proc pub:urban { nick uhost hand chan txt } { 
	global bind
	if {[llength [split $txt]] >= 1} {
		regsub -all {( )} $txt "%20" term
		set baseurl "http://api.urbandictionary.com/v0/define?term="
		set url "$baseurl$term"
		set out [exec wget -q -O - --bind-address=$bind $url]
		if {[regexp -nocase {"word"\:"(.*?)"\,"author":"(.*?)"\,"permalink"\:"(.*?)"\,"definition"\:"(.*?)"\,"example":"(.*?)"\,"thumbs_up"\:} $out match word auth perma def example]} { 
			outspd "PRIVMSG $chan : Urban - $word: $def"
		} else { 
			outspd "PRIVMSG $chan :An error occured"
		}
	} else { 
		outspd "PRIVMSG $chan :Oh dear...you seem to have forgotten the term!"
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
	global bind botnick htmlmap
	set baseurl "http://gdata.youtube.com/feeds/api/videos"
	set url "$baseurl/$vid"
	set out [exec /usr/bin/wget -q -O - --bind-address=$bind $url]
	if {[regexp {(.*?)\<title type\=\'text\'\>(.*?)\<\/title\>\<content type\=\'text\'\>(.*?)\<\/content\>.+} $out match j1 title desc]} {
		set title [uneschtml $title]
		set desc [uneschtml $desc]
		outspd "PRIVMSG $chan :\002\00301,00You\00300,04Tube\003 Title\002: \0032$title\003 - \002Desc\002 \0032$desc\003 "
	}
}
proc parse:vimeo { vid chan } { 
	global bind
	set baseurl "http://vimeo.com/api/v2/video"
	set url "$baseurl/$vid.xml"
	set out [exec /usr/bin/wget -q -O - --bind-address=$bind $url]
	if {[regexp -nocase {(.*?)<title>(.*?)</title><description>(.*?)</description>(.*?)<stats_number_of_likes>(.*?)</stats_number_of_likes><stats_number_of_plays>(.*?)</stats_number_of_plays>} $out match j1 title desc j2 likes plays]} {
		set title [uneschtml $title]
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
				mvFile $reg $new $bak
				return 1
			}
		}
		set fd [open $reg "a+"]
		puts -nonewline $fd "\n$nick:$code"
		close $fd
		return 1
	} else { 
		return 0
	}
}
#Last spoke
proc add:lastmsg { chan nick msg } {
	global lEnd
    set reg "lastsaid.db"	
	set fd [open $reg "r"]
	set fdata [read $fd]
	set data [split $fdata "\n"]
	set new "$reg.new"
	set bak "$reg.bak"
	close $fd
			
	set i 0
	foreach line $data {
		set i [expr $i + 1]
		set c [string trim [lindex [split $line ":"] 0]]
		set n [string trim [lindex [split $line ":"] 1]]
		set m [string trim [lindex [split $line ":"] 2]]
		if {$n == $nick} {
			set num [expr $i - 1]
			set nData [lreplace $data $num $num "$chan:$nick:$msg"]
			set fdn [open $new "w+"]
			foreach line $nData {
				puts -nonewline $fdn "$line\n"
			}
			close $fdn
			mvFile $reg $new $bak
			return 1
		}
	}
	set fd [open $reg "a+"]
	puts -nonewline $fd "\n$chan:$nick:$msg"
	close $fd
	return 1
}
proc search:lastmsg { chan nick } {
	
	set fd [open lastsaid.db "r"]
	set fdata [read $fd]
	set data [split $fdata "\n"]
	close $fd		
		
	foreach line $data {
		if {[regexp -nocase {^(.*?):(.*?):(.*?)$} $line match c n m]} {
			if {$n == $nick} {
				if {$c == $chan} {
					return $m
				}
			}
		}
	}
	return "File not found"
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
if {![file exists lastsaid.db]} { 
	[exec touch lastsaid.db]
}
proc uneschtml {text} {
	if {![regexp & $text]} { set text } else {
		regsub -all {([][$\\])} $text {\\\1} text
		regsub -all {&#([0-9][0-9]?[0-9]?);?} $text {[format %c [scan \1 %d tmp;set tmp]]} text
		regsub -all {&([a-zA-Z]+);?} $text {[uneschtml_map \1]} text
		subst -novariables $text
	}
}
## Convert an HTML escape sequence into character (used only by uneschtml):
proc uneschtml_map {text {unknown ?}} { 
	global eschtml_map
	if {[info exists eschtml_map($text)]} { 
		set eschtml_map($text) 
	} else { 
		set unknown 
	}
}
putlog "Matt's Tools V$ver loaded"