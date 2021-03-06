use utf8;
package PfamDB::Pfama2pfamaScoop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PfamDB::Pfama2pfamaScoop

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pfamA2pfamA_scoop>

=cut

__PACKAGE__->table("pfamA2pfamA_scoop");

=head1 ACCESSORS

=head2 pfama_acc_1

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 7

=head2 pfama_acc_2

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 7

=head2 score

  data_type: 'float'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pfama_acc_1",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 7 },
  "pfama_acc_2",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 7 },
  "score",
  { data_type => "float", default_value => 0, is_nullable => 0 },
);

=head1 RELATIONS

=head2 pfama_acc_1

Type: belongs_to

Related object: L<PfamDB::Pfama>

=cut

__PACKAGE__->belongs_to("pfama_acc_1", "PfamDB::Pfama", { pfama_acc => "pfama_acc_1" });

=head2 pfama_acc_2

Type: belongs_to

Related object: L<PfamDB::Pfama>

=cut

__PACKAGE__->belongs_to("pfama_acc_2", "PfamDB::Pfama", { pfama_acc => "pfama_acc_2" });


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-22 10:42:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hwvJHEnRShbKihjM5JPhfw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
