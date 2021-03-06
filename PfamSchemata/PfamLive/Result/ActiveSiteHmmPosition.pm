use utf8;
package PfamLive::Result::ActiveSiteHmmPosition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PfamLive::Result::ActiveSiteHmmPosition

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<_active_site_hmm_positions>

=cut

__PACKAGE__->table("_active_site_hmm_positions");

=head1 ACCESSORS

=head2 pfama_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 7

=head2 pfamseq_acc

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 hmm_position

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 residue

  data_type: 'tinytext'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pfama_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 7 },
  "pfamseq_acc",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "hmm_position",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "residue",
  { data_type => "tinytext", is_nullable => 0 },
);

=head1 RELATIONS

=head2 pfama_acc

Type: belongs_to

Related object: L<PfamLive::Result::PfamA>

=cut

__PACKAGE__->belongs_to(
  "pfama_acc",
  "PfamLive::Result::PfamA",
  { pfama_acc => "pfama_acc" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-07-06 13:42:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h8/smvcn9cz8AgdDN9K3Rg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
