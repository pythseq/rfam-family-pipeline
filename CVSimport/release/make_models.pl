#!/usr/local/bin/perl -w

BEGIN {
    $rfam_mod_dir = 
        (defined $ENV{'RFAM_MODULES_DIR'})
            ?$ENV{'RFAM_MODULES_DIR'}:"/pfam/db/Rfam/scripts/Modules";
}

use lib $rfam_mod_dir;

use strict;
use Rfam;
use RfamRCS;

my $tmpspace = "/tmp";
chdir "$tmpspace" or die;

my $list;
my $db = Rfam::default_db();
foreach my $acc ( $db->get_allacc() ) {
    system "cp $Rfam::current_dir/$acc/CM $acc.cm" and die;
    $list .= "$acc.cm ";
}
system "tar -cvf - $list" and die;
