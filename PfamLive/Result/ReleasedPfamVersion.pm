use utf8;
package PfamLive::Result::ReleasedPfamVersion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PfamLive::Result::ReleasedPfamVersion

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<released_pfam_version>

=cut

__PACKAGE__->table("released_pfam_version");

=head1 ACCESSORS

=head2 pfama_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 7

=head2 seed

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 align

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 desc_file

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 hmm

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 version

  data_type: 'smallint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pfama_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 7 },
  "seed",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "align",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "desc_file",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "hmm",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "version",
  { data_type => "smallint", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-05-19 08:45:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ln9R9Xft0EAlzIoWlpAKsQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
