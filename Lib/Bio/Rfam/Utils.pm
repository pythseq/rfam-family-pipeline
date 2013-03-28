package Bio::Rfam::Utils;

#TODO: add pod documentation to all these functions

#Occasionally useful Rfam utilities

use strict;
use warnings;
use Sys::Hostname;
use File::stat;
use Carp;

use Cwd;
use Data::Dumper;
use Mail::Mailer;
use File::Copy;
use vars qw( @ISA
             @EXPORT
);

@ISA    = qw( Exporter );

#Returns true if the CM file has been calibrated:
sub isCmCalibrated {
    my $cm = shift; #Handed a CM file generated by cmbuild and hopefully cmcalibrate'd
    $cm = 'CM' if not defined $cm;
    return 0 if not -s $cm;

    open(CM, "< $cm") or die "FATAL: failed to open the file $cm for a calibration check\n[$!]";
    my $ok=0;
    while(<CM>){
	if (/^ECMLC/){
	#if (/^CCOM.+cmcalibrate/){
	   $ok=1;
	   last;
	}
    }
    return $ok;
}

sub wait_for_farm {
    
    my ($bjobname, $jobtype, $nobjobs, $toKill, $debug) = @_;
    
    my $wait = 1;
    my $bjobcount = 1;
    my $bjobinterval = 15;
    my $jobs = $nobjobs;
    my $startTime = time();
    my $nowTime=0;
    my $firstRun;
    while($wait){
	
	sleep($bjobinterval); 
	
	$jobs = 0;
	my ($bjpend, $bjrun)  = (0, 0);
	open(S, "bjobs -J $bjobname |") or die "FATAL: failed to open pipe \'bjobs -J $bjobname |\'\n[$!]";
	while(<S>) {
	    $bjpend++ if (/PEND/);
	    $bjrun++ if (/RUN/);
	    if (/RUN/ && not defined $firstRun){
		$firstRun = time();
	    }
	}
	close(S);
	$jobs = $bjpend + $bjrun;
	
	$jobs = $nobjobs if $jobtype eq 'cmcalibrate' && $bjrun == 1;
	
	if ($jobs < int($nobjobs*(1-0.95)) ){#Once 95% of jobs are finished, check frequently.
	    $bjobinterval=15;
	}      
	elsif ($jobs < int($nobjobs*(1-0.90)) ){#Once 90% of jobs are finished, check a little more frequently.
	    $bjobinterval=15 + int(log($bjobcount/2)); 
	}
	else {#otherwise check less & less frequently (max. interval is ~300 secs = 5 mins).
	    if ($bjobinterval<300){ $bjobinterval = $bjobinterval + int(log($bjobcount));}
	}
	
	if($jobs){
	    $nowTime = time();
	    my @humanTime = gmtime($nowTime-$startTime);
	    printf STDERR "There are $jobs $jobtype jobs of $nobjobs still running after $bjobcount checks (PEND:$bjpend,RUN:$bjrun). Check interval:$bjobinterval secs [TotalTime=%dD:%dH:%dM:%dS].\n", @humanTime[7,2,1,0]; 
	    if(defined $toKill && defined $firstRun && ($nowTime-$firstRun)>$toKill){
		printf STDERR "WARNING: this job is taking too long therefore I am backing out. Hopefully it'll restart nicely.\n";
		#########
		#DEBUG -- MOSTLY TO TRACK DOWN MPI PROBLEMS:
		#MAKES A FILE FOR EACH MPIRUN NODE CONTAINING STRACE INFO AND PS.
		if (defined $debug){
		    printf STDERR "DEBUG start!\n";
		    
		    my $user =  'pg5';
		    $user =  getlogin() if defined getlogin();
		    my $pwd = getcwd;
		    print "DEBUG: pwd=$pwd, user=$user\n";
		    open(S, "bjobs -J $bjobname |") or die "FATAL: failed to open pipe \'bjobs -J $bjobname |\'\n[$!]";
		    while(<S>) {
			if(/(\d+)\*(bc-\S+)/){
			    my $node = $2;
			    print "node: $node\n";
			    open(B, "ssh $node ps -U $user -o pid,user,\%cpu,\%mem,cmd --sort cmd |") or warn "FATAL: failed to open pipe [ssh $node ps -U $user -o pid,user,\%cpu,\%mem,cmd --sort cmd]\n[$!]";
			    while(my $b=<B>) {
				print $b;
				if($b=~/(\d+)\s+\S+\s+(\S+)\s+(\S+).+$debug/){
				    # 6456 pg5      99.7  0.1 /software/rfam/share/infernal-1.0/bin/cmcalibrate --mpi -s 1 CM
				    my $debugFile="\$HOME/$$\.mpi.debug.$debug.$1.$node";
				    print("ssh $node \'strace -p $1 -o $debugFile\'");
				}
			    }	    
			    close(B);
			}
		    }
		    close(S);
		}
		printf STDERR "DEBUG end!\n";
		#DEBUG ENDS
		########
		system("bkill -J $bjobname ") and die "FATAL: failed to run [bkill -J $bjobname]\n[$!]";
	    }
	}else{
	    $wait = 0;
	}
	$bjobcount++;
    }
    
    return 1;
    
}

######################################################################

# FROM RfamUtils.pm:

######################################################################
#reorder: given 2 integers, return the smallest first & the largest last:
sub reorder {
    my ($x,$y)=@_;
    
    if ($y<$x){
	my $tmp = $x;
	$x = $y;
	$y = $tmp;
    }
    return ($x,$y);
}

#max
sub max {
  return $_[0] if @_ == 1;
  $_[0] > $_[1] ? $_[0] : $_[1]
}

#min
sub min {
  return $_[0] if @_ == 1;
  $_[0] < $_[1] ? $_[0] : $_[1]
}


######################################################################
# Returns the extent of overlap between two regions A=($x1, $y1) and B=($x2, $y2):
# - assumes that $x1 < $y1 and $x2 < $y2.
#
sub overlapExtent {
    my($x1, $y1, $x2, $y2) = @_;
    
    if($x1 > $y1) { die "ERROR overlapExtent, expect x1 <= y1 but $x1 > $y1"; }
    if($x2 > $y2) { die "ERROR overlapExtent, expect x2 <= y2 but $x2 > $y2"; }

    my $L1=$y1-$x1+1;
    my $L2=$y2-$x2+1;
    my $minL = Bio::Rfam::TempRfam::min($L1, $L2);
    
    my $D = overlapNres($x1, $y1, $x2, $y2);
    return $D/$minL;
}

######################################################################
# Returns the number of residues of overlap between two regions A=($x1, $y1) and B=($x2, $y2):
# - assumes that $x1 < $y1 and $x2 < $y2.
#
sub overlapNres {

    my($x1, $y1, $x2, $y2) = @_;
    
    if($x1 > $y1) { die "ERROR overlapNres, expect x1 <= y1 but $x1 > $y1"; }
    if($x2 > $y2) { die "ERROR overlapNres, expect x2 <= y2 but $x2 > $y2"; }

    # 1.
    # x1                   y1
    # |<---------A--------->|
    #    |<------B------>|
    #    x2             y2
    #    XXXXXXXXXXXXXXXXX
    #
    # 2.  x1                     y1
    #     |<---------A----------->|
    # |<-------------B------>|
    # x2                    y2
    #     XXXXXXXXXXXXXXXXXXXX
    #
    # 3. x1             y1
    #    |<------A------>|
    # |<---------B--------->|
    # x2                   y2
    #    XXXXXXXXXXXXXXXXX
    #
    # 4. x1                    y1
    #    |<-------------A------>|
    #        |<---------B----------->|
    #        x2                     y2
    #        XXXXXXXXXXXXXXXXXXXX
    my $D=0;
    my $int=0;
    my $L1=$y1-$x1+1;
    my $L2=$y2-$x2+1;
    my $minL = Bio::Rfam::TempRfam::min($L1, $L2);

    if ( ($x1<=$x2 && $x2<=$y1) && ($x1<=$y2 && $y2<=$y1) ){    #1.
	$D = $L2;
    }
    elsif ( ($x2<=$x1) && ($x1<=$y2 && $y2<=$y1) ){              #2.
	$D = $y2-$x1+1;
    }
    elsif ( ($x2<=$x1 && $x1<=$y2) && ($x2<=$y1 && $y1<=$y2) ){ #3.
	$D = $L1;
    }
    elsif ( ($x1<=$x2 && $x2<=$y1) && ($y1<=$y2) ){              #4.
	$D = $y1-$x2+1;
    }
    return $D;
}

######################################################################
#species2shortspecies: Given a species string eg. "Homo sapiens
#                      (human)" generate a nicely formated short name
#                      with no whitespace eg. "H.sapiens".
sub species2shortspecies {
    my $species = shift;
    my $shortSpecies;
    
    if ($species=~/(.*)\s+sp\./){
	$shortSpecies = $1;
    }
    elsif ($species=~/metagenome/i or $species=~/uncultured/i){
	$species=~s/metagenome/metag\./gi;
	$species=~s/uncultured/uncult\./gi;
	my @w = split(/\s+/,$species);
	if(scalar(@w)>2){
	    foreach my $w (@w){
		$shortSpecies .= substr($w, 0, 5) . '.';
	    }
	}
	else {
	    $shortSpecies = $species;
	    $shortSpecies =~ s/\s+/_/g;
	}
    }#lots of conditions here. Need else you get some ridiculous species names.
    elsif($species=~/^(\S+)\s+(\S{4,})/ && $species!~/[\/\-\_0-9]/ && $species!~/^[a-z]/ && $species!~/\svirus$/ && $species!~/\svirus\s/ && $species!~/^Plasmid\s/i && $species!~/\splasmid\s/i){
	$shortSpecies = substr($1,0,1) . "." . $2; 
    }
    else {
	$shortSpecies = $species;
    }
    
    $shortSpecies =~ s/\s+/_/g;
    $shortSpecies =~ s/[\'\(\)\:\/]//g;
    $shortSpecies = substr($shortSpecies,0,20) if (length($shortSpecies) > 20);
    
#   H.P 
    return $shortSpecies;
}

sub tax2kingdom {
    my ($species, $huge) = @_;
    my $kingdom;
    #unclassified sequences; metagenomes; ecological metagenomes.
    if ($species=~/^(.+?);\s+(.+?)\.*?;/){
	$kingdom = "$1; $2";
	$kingdom = $1 if defined $huge;
    }
    die "FATAL: failed to parse a kingdom from species string: [$species]. email pg5!" if not defined $kingdom;
    
    return $kingdom;
}

=head2 nse_breakdown

  Title    : nse_breakdown
  Incept   : EPN, Wed Jan 30 09:50:07 2013
  Usage    : nse_breakdown($nse)
  Function : Checks if $nse is of format "name/start-end" and if so
           : breaks it down into $n, $s, $e, $strand (see 'Returns' section)
  Args     : <sqname>: seqname, possibly of format "name/start-end"
  Returns  : 4 values:
           :   '1' if seqname was of "name/start-end" format, else '0'
           :   $n: name ("" if seqname does not match "name/start-end")
	   :   $s: start, maybe <= or > than $e (0 if seqname does not match "name/start-end")
	   :   $e: end,   maybe <= or > than $s (0 if seqname does not match "name/start-end")

=cut

sub nse_breakdown {
    my ($sqname) = @_;

    my $n;       # sqacc
    my $s;       # start, from seq name (can be > $end)
    my $e;       # end,   from seq name (can be < $start)

    if($sqname =~ m/^(\S+)\/(\d+)\-(\d+)\s*/) {
	($n, $s, $e) = ($1,$2,$3);
	return (1, $n, $s, $e);
    }
    return (0, "", 0, 0);
}


=head2 nse_sqlen

  Title    : nse_sqlen
  Incept   : EPN, Thu Jan 31 10:08:24 2013
  Usage    : nse_sqlen($name);
  Function : Returns length of sequence given $nse,
           : where $nse is of format:
           : <sqacc>/<start>-<end>
           : and <start> may be > <end>.
  Args     : $nse: sequence name in <sqacc>/<start>-<end> format
  Returns  : Length in residues represented by $nse

=cut

sub nse_sqlen {
    my ($nse) = @_;

    my $sqlen;
    if($nse =~ m/^\S+\/(\d+)\-(\d+)\s*/) {
	my ($start, $end) = ($1, $2);
	if($start <= $end) { $sqlen = $end - $start + 1; }
	else               { $sqlen = $start - $end + 1; }
    }
    else { 
	croak "invalid name $nse does not match name/start-end format\n";
    }
    return $sqlen;
}


=head2 _max

  Title    : _max
  Incept   : EPN, Thu Jan 31 08:55:18 2013
  Usage    : _max($a, $b)
  Function : Returns maximum of $a and $b.
  Args     : $a: scalar, usually a number
           : $b: scalar, usually a number
  Returns  : Maximum of $a and $b.

=cut

sub _max {
  return $_[0] if @_ == 1;
  $_[0] > $_[1] ? $_[0] : $_[1]
}

=head2 _min

  Title    : _min
  Incept   : EPN, Thu Jan 31 08:56:19 2013
  Usage    : _min($a, $b)
  Function : Returns minimum of $a and $b.
  Args     : $a: scalar, usually a number
           : $b: scalar, usually a number
  Returns  : Minimum of $a and $b.

=cut

sub _min {
  return $_[0] if @_ == 1;
  $_[0] < $_[1] ? $_[0] : $_[1]
}

=head2 overlap_fraction_two_nse

  Title    : overlap_fraction_two_nse
  Incept   : EPN, Thu Feb  7 14:47:37 2013
  Usage    : overlap_fraction_two_nse($nse1, $nse2)
  Function : Returns fractional overlap of two regions defined by
           : $nse1 and $nse2. Where $nse1 and $nse2 are both of
           : format "name/start-end".
  Args     : <nse1>: "name/start-end" for region 1
           : <nse2>: "name/start-end" for region 2
  Returns  : Fractional overlap between region 1 and region 2
           : (This will be 0. if names are different for regions 1 and 2.)
           : (This will be 0. if regions are on different strands.)

=cut

sub overlap_fraction_two_nse {
    my ($nse1, $nse2) = @_;

    my($is1, $n1, $s1, $e1) = nse_breakdown($nse1);
    if(! $is1) { croak "$nse1 not in name/start-end format"; }
    my($is2, $n2, $s2, $e2) = nse_breakdown($nse2);
    if(! $is2) { croak "$nse2 not in name/start-end format"; }

    if($n1 ne $n2) { return 0.; } #names don't match

    return overlap_fraction($s1, $e1, $s2, $e2);
}

=head2 overlap_fraction

  Title    : overlap_fraction
  Incept   : EPN, Thu Jan 31 08:50:55 2013
  Usage    : overlap_fraction($from1, $to1, $from2, $to2)
  Function : Returns fractional overlap of two regions.
           : If $from1 is <= $to1 we assume first  region is 
           : on + strand, else it's on -1.
           : If $from2 is <= $to2 we assume second region is 
           : on + strand, else it's on -1.
           : If regions are on opposite strand, return 0.
  Args     : $from1: start point of first region (maybe < or > than $to1)
           : $to1:   end   point of first region
           : $from2: start point of second region (maybe < or > than $to2)
           : $to2:   end   point of second region
  Returns  : Fractional overlap, defined as nres_overlap / minL
             where minL is minimum length of two regions
=cut

sub overlap_fraction {
    my($from1, $to1, $from2, $to2) = @_;
    
    my($a1, $b1, $strand1, $a2, $b2, $strand2);

    if($from1 <= $to1) { $a1 = $from1; $b1 = $to1;   $strand1 = 1;  }
    else               { $a1 = $to1;   $b1 = $from1; $strand1 = -1; }

    if($from2 <= $to2) { $a2 = $from2; $b2 = $to2;   $strand2 = 1;  }
    else               { $a2 = $to2;   $b2 = $from2; $strand2 = -1; }
    
    if($strand1 != $strand2) { 
	return 0.; 
    }

    my $L1 = $b1 - $a1 + 1;
    my $L2 = $b2 - $a2 + 1;
    my $minL = _min($L1, $L2);
    my $D    = overlap_nres_strict($a1, $b1, $a2, $b2);
    # printf STDERR "D: $D minL: $minL\n";
    return $D / $minL;
}


=head2 overlap_nres_strict

  Title    : overlap_nres_strict
  Incept   : EPN, Thu Jan 31 08:50:55 2013
  Usage    : overlap_nres_strict($from1, $to1, $from2, $to2)
  Function : Returns number of overlapping residues of two regions.
  Args     : $from1: start point of first region (must be <= $to1)
           : $to1:   end   point of first region
           : $from2: start point of second region (must be <= $to2)
           : $to2:   end   point of second region
  Returns  : Number of residues that overlap between the two regions.

=cut

sub overlap_nres_strict {
    my ($from1, $to1, $from2, $to2) = @_;
    
    if($from1 > $to1) { croak "overlap_nres_strict(), from1 > to1\n"; }
    if($from2 > $to2) { croak "overlap_nres_strict(), from2 > to2\n"; }

    my $minlen = $to1 - $from1 + 1;
    if($minlen > ($to2 - $from2 + 1)) { $minlen = ($to2 - $from2 + 1); }

    # Given: $from1 <= $to1 and $from2 <= $to2.

    # Swap if nec so that $from1 <= $from2.
    if($from1 > $from2) { 
	my $tmp;
	$tmp   = $from1; $from1 = $from2; $from2 = $tmp;
	$tmp   =   $to1;   $to1 =   $to2;   $to2 = $tmp;
    }

    # 3 possible cases:
    # Case 1. $from1 <=   $to1 <  $from2 <=   $to2  Overlap is 0
    # Case 2. $from1 <= $from2 <=   $to1 <    $to2  
    # Case 3. $from1 <= $from2 <=   $to2 <=   $to1
    if($to1 < $from2) { return 0; }                    # case 1
    if($to1 <   $to2) { return ($to1 - $from2 + 1); }  # case 2
    if($to2 <=  $to1) { return ($to2 - $from2 + 1); }  # case 3
    croak "unforeseen case in _overlap_nres_strict $from1..$to1 and $from2..$to2";
}

######################################################################

=head1 AUTHOR

Sarah Burge, swb@ebi.ac.uk

=head1 COPYRIGHT

Copyright (c) 2013: European Bioinformatics Institute

Authors: Sarah Burge swb@ebi.ac.uk

This is based on code taken from the Rfam modules at the Sanger institute.

This is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.

=cut

1;



