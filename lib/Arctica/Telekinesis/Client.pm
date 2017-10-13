################################################################################
#          _____ _
#         |_   _| |_  ___
#           | | | ' \/ -_)
#           |_| |_||_\___|
#                   _   _             ____            _           _
#    / \   _ __ ___| |_(_) ___ __ _  |  _ \ _ __ ___ (_) ___  ___| |_
#   / _ \ | '__/ __| __| |/ __/ _` | | |_) | '__/ _ \| |/ _ \/ __| __|
#  / ___ \| | | (__| |_| | (_| (_| | |  __/| | | (_) | |  __/ (__| |_
# /_/   \_\_|  \___|\__|_|\___\__,_| |_|   |_|  \___// |\___|\___|\__|
#                                                  |__/
#          The Arctica Modular Remote Computing Framework
#
################################################################################
#
# Copyright (C) 2015-2016 The Arctica Project 
# http://arctica-project.org/
#
# This code is dual licensed: strictly GPL-2 or AGPL-3+
#
# GPL-2
# -----
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
#
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# AGPL-3+
# -------
# This programm is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This programm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Copyright (C) 2015-2016 Guangzhou Nianguan Electronics Technology Co.Ltd.
#                         <opensource@gznianguan.com>
# Copyright (C) 2015-2016 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>
#
################################################################################
package Arctica::Telekinesis::Client;
use strict;
use Exporter qw(import);
use Data::Dumper;
use Arctica::Core::eventInit qw( genARandom BugOUT );
# Be very selective about what (if any) gets exported by default:
our @EXPORT = qw();
# And be mindfull of what we lett the caller request here too:
our @EXPORT_OK = qw();

my $arctica_core_object;

sub new {
	BugOUT(9,"TeKi Client new->ENTER");
	my $class_name = $_[0];# Be EXPLICIT!! DON'T SHIFT OR "@_";
	$arctica_core_object = $_[1];
	my $the_tmpdir = $arctica_core_object->{'a_dirs'}{'tmp_adir'};
	my $teki_tmpdir = "$the_tmpdir/teki";
	unless (-d $teki_tmpdir) {
		mkdir($teki_tmpdir) or die("TeKi Client unable to create TMP dir $teki_tmpdir ($!)");
	}
	my $self = {
		tmpdir => $teki_tmpdir,
		isArctica => 1, # Declare that this is a Arctica "something"
		aobject_name => "Telekinesis_Client",
		available_services => {
			multimedia => 1,
			webcontent => 1,
		},
	};
#	$self->{'session_id'} = genARandom('id');
	$self->{'state'}{'active'} = 0;
	bless($self, $class_name);
	$arctica_core_object->{'aobj'}{'Telekinesis_Client'} = \$self;

	BugOUT(9,"TeKi Client new->DONE");
	return $self;
}

sub csapp_reg {
	my $self = $_[0];
#	print "CSAPPREG:\t$_[1]\n",Dumper(@_),"\n";
	my $app_id = $_[1];
	$self->{'running_apps'}{$app_id}{'state'} = 1;
	$self->{'socks'}{'remote'}->client_send('appinit',$app_id)
}

sub app_init_win_and_targets {
	my $self = $_[0];
	my $app_id = $_[1];
	my $init_data = $_[2];
	if ($self->{'running_apps'}{$app_id}) {
#	print "DUMP YOUR RUMP:\t$app_id\t\n",Dumper($init_data);
		if ($init_data->{'windows'}) {
			foreach my $wid (sort keys %{$init_data->{'windows'}}) {
#				print "WINDOW:\t$wid\t\n",#
				$self->{'running_apps'}{$app_id}{'windows'}{$wid} = $init_data->{'windows'}{$wid};
			}
		}
		if ($init_data->{'targets'}) {
			foreach my $ttid (sort keys %{$init_data->{'targets'}}) {
#				print "TARGETS:\t$ttid\t\n",Dumper($init_data->{'targets'}{$ttid});
				$self->{'running_apps'}{$app_id}{'targets'}{$ttid} = $init_data->{'targets'}{$ttid};
				if ($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}) {
					if ($self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}) {
						$self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'targets'}{$ttid} = 1;
					}
				}
				$self->target_spawn($app_id,$ttid);
			}
		}
	}
}



sub target_spawn {
	my $self = $_[0];
	my $app_id = $_[1];
	my $ttid = $_[2];
	if ($app_id =~ /^([a-zA-Z0-9\_\-]*)$/) {
		$app_id = $1;
	} else {
		die("!!!");
	}
	if ($ttid =~ /^([a-zA-Z0-9\_\-]*)$/) {
		$ttid = $1;
	} else {
		die("!!!");
	}
	
#	print "Spawning target:\t$app_id\n$ttid\n";
	if ($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'service'} eq 'multimedia') {
		if ($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'tmplnkid'}) {#TMP GARBAGE 
#			print "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n\n\nYAY IT MADE IT THIS FAR\nID:\t$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'tmplnkid'}\n\n";
#print Dumper($self->{'running_apps'}{$app_id});
# obviously want to do this in a more elegant and generic fashion! (but Mother::Forker is a bit overkill here since we're going to chitchat on JABus)

#print "<<<<<<<<<<<<<SPAWN>>>>>>>>>>>>>>>>\n";

#		my $pid = open(my $fh,"|-",'./forkedmmoverlay.pl',$app_id,$ttid,$self->{'socks'}{'local'}{'_socket_id'});
			my $mfid = 0;
			my $rwid = 0;
		        if ($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'tmplnkid'} =~ /^([a-zA-Z0-9\_\-]*)$/) {
				$mfid = $1;
			}
		        if ($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'realwid'} =~ /^([a-zA-Z0-9\_\-]*)$/) {
				$rwid = $1;
			}


			if (($mfid ne 0)  and ($rwid ne 0)) {
				system("/usr/bin/arctica-mediaplayer-overlay $app_id $ttid $self->{'socks'}{'local'}{'_socket_id'} $mfid $rwid&");
			}
                }
	} elsif ($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'service'} eq 'webcontent') {
		my $nxwid = 0;
		my $rwid = 0;
		        if ($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'realwid'} =~ /^([a-zA-Z0-9\_\-]*)$/) {
				$rwid = $1;
			}
		system("/usr/bin/arctica-browser-overlay $app_id $ttid $self->{'socks'}{'local'}{'_socket_id'} $nxwid $rwid&");
		BugOUT(8,"WebContent!!!");
	} else {
		warn("Unknown service $self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'service'}");
	}
}


sub target_reg {
	my $self = $_[0];
	my $sclient_id = $_[2];
	my $data = $_[1];
	if ($data->{'app_id'} and $data->{'ttid'}) {
		warn "HELLO $sclient_id";
		if ($self->{'running_apps'}{$data->{'app_id'}}{'targets'}{$data->{'ttid'}}) {
			$self->{'running_apps'}{$data->{'app_id'}}{'targets'}{$data->{'ttid'}}{'scli_id'} = $sclient_id;
		}
	} else {
		die("WTF");
	}
}

sub target_state_change {
	my $self = $_[0];
	my $app_id = $_[1];
	my $data = $_[2];
	my %ch_targets;

	if ($self->{'running_apps'}{$app_id}) {
		if ($data->{'data'}{'w'}) {
#			print "DATA/W:\n";
			foreach my $wid (keys %{$data->{'data'}{'w'}}) {
#				print "\t$wid\n";
				if ($data->{'data'}{'w'}{$wid} and $self->{'running_apps'}{$app_id}{'windows'}{$wid}) {
#					print "\t\tDEEPER 1\n";
					foreach my $key (keys %{$data->{'data'}{'w'}{$wid}}) {
#						print "\t\t\tDEEPER 2:\t$key\n";
						if ($data->{'data'}{'w'}{$wid}{$key} ne $self->{'running_apps'}{$app_id}{'windows'}{$wid}{'state'}{$key}) {
#							print "\t\t\t\tD3:\t[$data->{'data'}{'w'}{$wid}{$key}]\t[$self->{'running_apps'}{$app_id}{'windows'}{$wid}{'state'}{$key}]\n";
							$self->{'running_apps'}{$app_id}{'windows'}{$wid}{'state'}{$key} = $data->{'data'}{'w'}{$wid}{$key};
						}
					}
#					    $self->{'running_apps'}{$app_id}{'windows'}{$wid}{'targets'}
					if ($self->{'running_apps'}{$app_id}{'windows'}{$wid}{'targets'}) {
						foreach my $ttid (keys %{$self->{'running_apps'}{$app_id}{'windows'}{$wid}{'targets'}}) {
							$ch_targets{$ttid} = 1;
#							print "\t\t\t\t\tWCHT:$ttid\n";
						}
					}
				}
			}
		}

		if ($data->{'data'}{'t'}) {
#			warn("DATA/T:");
			foreach my $ttid (keys %{$data->{'data'}{'t'}}) {
#				print "\t$ttid\n";
				if ($data->{'data'}{'t'}{$ttid} and $self->{'running_apps'}{$app_id}{'targets'}{$ttid}) {
#					print "\t\tDEEPER 1\n";
					foreach my $key (keys %{$data->{'data'}{'t'}{$ttid}}) {
#						print "\t\t\tDEEPER 2:\t$key\n";
						if ($data->{'data'}{'t'}{$ttid}{$key} ne $self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}{$key}) {
#							if  ($data->{'data'}{'t'}{$ttid}{'alive'}) {


#							}
#							print "\t\t\t\tD3:\t[$data->{'data'}{'t'}{$ttid}{$key}]\t[$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}{$key}]\n";
							$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}{$key} = $data->{'data'}{'t'}{$ttid}{$key};
						}
						$ch_targets{$ttid} = 1;
#						print "\t\t\t\t\tTCHT:$ttid\n";
					}
				}
			}
		}
	}
	
	foreach my $ttid (keys %ch_targets) {
		$self->target_send_state_changes($app_id,$ttid);
	}
#	print "STATE CHANGE!!!!\n",Dumper(%ch_targets);
}

sub target_send_state_changes {
#	warn("STATE CHANGE????????????????????????????");# FUCK ME
	my $self = $_[0];
	my $app_id = $_[1];
	my $ttid = $_[2];
	if ($self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'state'} and
		$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}) 
	{
#		print "WHAT THE!!:\n",Dumper($self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'state'});
#		my %ws = $self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'state'};
#		my $ts = $self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'};
		
		my $apx = (
#				$self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'state'}{'of_x'} +
				$self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'state'}{'x'}
				+ $self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}{'x'});

		my $apy = (
				#$self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'state'}{'of_y'}+
				$self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'state'}{'y'}
				+ $self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}{'y'});
		
		my $visible = 0;
		if (($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}{'viz'} eq 1) and ($self->{'running_apps'}{$app_id}{'windows'}{$self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'window'}}{'state'}{'map'} eq 1)) {
			$visible = 1;
		}
#		my $apy = 100;#($ws->{'of_y'}+$ws->{'os_y'}+$ts->{'y'});
#		print "SEND\n\tX:\t$ws->{'of_x'}+$ws->{'os_x'}+$ts->{'x'} ($apx)\n\tY:$ws->{'of_y'}+$ws->{'os_y'}+$ts->{'y'} $apy\n";
		if ($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'scli_id'}) {
			$self->{'socks'}{'local'}->server_send($self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'scli_id'},'chtstate',{
			visible => $visible,
			apy 	=> $apy,apx	=> $apx,
			h	=> $self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}{'h'},
			w	=> $self->{'running_apps'}{$app_id}{'targets'}{$ttid}{'state'}{'w'},
			});
		}
	}
}

################################################################################
# Stuff that will eventually be replaced:


sub init_c2s_service_neg {
	my $self = $_[0];
################################################################################
# This is just a "dummy" place holder for the real negotiation function
################################################################################
# In step one we tell the server what services we have.... 
# probably with some more info like... versions etc....
	BugOUT(9,"Service Negotiation Step 0");
	$self->{'socks'}{'remote'}->client_send('srvcneg',{
		step => 1,
		services => {
			multimedia => 1,
			webcontent => 1,
		}
	})
}


sub c2s_service_neg {
	my $self = $_[0];
################################################################################
# This is just a "dummy" place holder for the real negotiation function
################################################################################
	my $jdata = $_[1];
#	print "SRVCNEG:\t",Dumper($jdata),"\n";
	if ($jdata->{'step'} eq 2) {
# Ok so here we're beign told what the server have and if we are newer version than server 
# we need to check compatibility...
# Send server a final list of services we'll be able to provide.
		BugOUT(9,"Service Negotiation Step 2");
		$self->{'socks'}{'remote'}->client_send('srvcneg',{
			step => 3,
			services => {
				multimedia => 1,
				webcontent => 1,
			}
		})
	}
}


sub get_tmp_servers_socket_id {
	my $self = $_[0];
	if (-f "$self->{'tmpdir'}/server_sockets.info") {
		open(SIF,"$self->{'tmpdir'}/server_sockets.info");
		my (undef,$remote_line) = <SIF>;
		close(SIF);
		$remote_line =~ s/[\n\s]//g;
		if ($remote_line =~ /^remote\:([0-9a-zA-Z]*)$/) {
			my $sock_id = $1;
			return $sock_id;
		} else {
			die("TOTAL FAILURE! BUHUHUHHUUUUUUUUUUU!");
		}
	} else {
		die("TOTAL FAILURE! BUHUHUHHUUUUUUUUUUU!");
	}
}

1;
