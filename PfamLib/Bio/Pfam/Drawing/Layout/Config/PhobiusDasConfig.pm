
# $Author: jt6 $

package Bio::Pfam::Drawing::Layout::Config::PhobiusDasConfig;
use strict;
use warnings;

use Bio::Pfam::Drawing::Layout::Config::GenericDasSourceConfig;
use Data::Dumper;
use vars qw($AUTOLOAD @ISA $VERSION);
@ISA= qw(Bio::Pfam::Drawing::Layout::Config::GenericDasSourceConfig);



#Configure the DAS source.


sub _setDrawingType{
    my($self, $feature) = @_;
    #Note, feature is an array ref....
    for(my $i = 0; $i < scalar(@$feature); $i++){
	if($feature->[$i]->{'end'} && $feature->[$i]->{'start'}){
	    $feature->[$i]->{'drawingType'} = "Region";
	}else{
	    $feature->[$i]->{'hidden'} = 1 ;
	}
    }
}

sub _setDrawingStyles{
    my ($self,$features) = @_;
    
    for(my $i = 0; $i < scalar(@$features); $i++){
	
	if($features->[$i]->{'type'} eq "SIGNAL"){
	    $features->[$i]->{'feature_label'} = "Signal peptide";
	    $self->_setRegionColours($features->[$i], "FF8000" );
	}elsif($features->[$i]->{'type'}  eq "TRANSMEM" ){
	    $features->[$i]->{'feature_label'} = "Transmembrane";
	    $self->_setRegionColours($features->[$i], "A05000" );
	}elsif($features->[$i]->{'type'}  eq "CYTOPLASMIC"){
	    $features->[$i]->{'feature_label'} = "Cytoplasmic";
	    $self->_setRegionColours($features->[$i], "FFFF00" );
	}elsif($features->[$i]->{'type'}  eq "NON-CYTOPLASMIC"){
	    $features->[$i]->{'feature_label'} = "Non-cytoplasmic";
	    $self->_setRegionColours($features->[$i], "FFFFFF" );
	}else{
	    $features->[$i]->{'hidden'} = 1;
	}
    }
}

=head1 COPYRIGHT

Copyright (c) 2007: Genome Research Ltd.

Authors: Rob Finn (rdf@sanger.ac.uk), John Tate (jt6@sanger.ac.uk)

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
