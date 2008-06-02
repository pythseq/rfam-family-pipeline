
# $Id: PfamA_HMM_fs.pm,v 1.3 2008-06-02 10:50:27 rdf Exp $
#
# $Author: rdf $

package PfamLive::PfamA_HMM_fs;

use strict;
use warnings;

use base "DBIx::Class";

__PACKAGE__->load_components( qw/Core/ );

#Set up the table
__PACKAGE__->table( 'pfamA_HMM_fs' );

#Get the columns that we want to keep
__PACKAGE__->add_columns( qw/auto_pfamA hmm_fs / );

__PACKAGE__->set_primary_key( 'auto_pfamA' );

__PACKAGE__->has_one( pfam => 'PfamLive::Pfam',
                      { 'foreign.auto_pfamA' => 'self.auto_pfamA' } );

__PACKAGE__->has_one( pfam_acc => 'PfamLive::Pfam',
                      { 'foreign.auto_pfamA' => 'self.auto_pfamA' },
		      {proxy => [qw/ pfamA_acc/]} );
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

