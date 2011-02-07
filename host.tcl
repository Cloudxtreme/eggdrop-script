# Change Log
# 0.1 
# * Basic work done so that you can query A, AAAA, PTR, NS, TXT, and MX records
#
# License 
#Copyright (c) 2010, Matthew McGowan
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#    * Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

bind PUB - !host pub:host
bind PUB - !hhelp pub:help 

proc pub:host { nick uhost hand chan txt } {
	set type [string trim [lindex [split $txt] 0]]
	set host [string trim [lindex [split $txt] 1]]
	if {$host != ""} {
		if {[regexp -nocase {^(a|4|ipv4)$} $type]} {
			set out [exec /usr/bin/host -tA $host]
			set addrs [split $out \n]
			foreach addr $addrs {
				regexp {(.*) has address (.*)} $addr match rHost output
				putnow "PRIVMSG $chan :$rHost => $output"
			}
		} elseif {[regexp -nocase {^(aaaa|6|ipv6)$} $type]} { 
			set out [exec host -tAAAA $host] 
			set addrs [split $out \n]
			foreach addr $addrs {
				regexp {(.*) has IPv6 address (.*)} $addr match rHost output
				putnow "PRIVMSG $chan :$rHost => $output"
			}
		} elseif {[regexp -nocase {^(mx)$} $type]} {
			set out [exec host -tMX $host] 
			set addrs [split $out \n]
			foreach addr $addrs {
				regexp {(.*) mail is handled by (.*) (.*)} $addr match rHost pri output
				putnow "PRIVMSG $chan :$rHost => $output"
			}
		} elseif {[regexp -nocase {^(txt)$} $type]} {
			set out [exec host -tTXT $host] 
			set addrs [split $out \n]
			foreach addr $addrs {
				regexp {(.*) descriptive text (.*)} $addr match rHost output
				putnow "PRIVMSG $chan :$rHost => $output"
			}
		} elseif {[regexp -nocase {^(ns)$} $type]} {
			set out [exec host -tNS $host] 
			set addrs [split $out \n]
			foreach addr $addrs {
				regexp {(.*) name server (.*)} $addr match rHost output
				putnow "PRIVMSG $chan :$rHost => $output"
			}
		} elseif {[regexp -nocase {^(ptr)$} $type]} {
			set out [exec host -tPTR $host] 
			set addrs [split $out \n]
			foreach addr $addrs {
			    if {[regexp {domain name pointer} $addr]} {
					regexp {domain name pointer (.*)} $addr output
					putnow "PRIVMSG $chan :$host => $output"
				}
			}
		}
	}
}
proc pub:help { nick uhost hand chan txt } {
	if {[llength [split $txt]] == 0} {
		putnow "NOTICE $nick :Basic Help For Matt's Host System"
		putnow "NOTICE $nick :-------Commands-------"
		putnow "NOTICE $nick :!host <a|aaaa|mx|txt> <host>"
	}
}