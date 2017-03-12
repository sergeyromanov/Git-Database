package Git::Database::Backend::Git::Raw::Repository;

use Git::Raw;
use Sub::Quote;
use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::RefReader',
  'Git::Database::Role::RefWriter',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Raw::Repository object'
          if !eval { $_[0]->isa('Git::Raw::Repository') }
    } ),
);

# Git::Database::Role::RefReader
sub refs {
    my ($self) = @_;
    return {
        map +( $_->name => $self->_deref($_->target)->id ),
        # we include HEAD explicitly to mimic `show-ref --head`
        Git::Raw::Reference->lookup('HEAD', $self->store), $self->store->refs
    };
}

sub _deref {
    my ($self, $maybe_ref) = @_;
    return $maybe_ref->isa('Git::Raw::Reference')
      ? $self->_deref($maybe_ref->target)
      : $maybe_ref;
}

# Git::Database::Role::RefWriter
sub put_ref {
    my ($self, $refname, $digest) = @_;
    Git::Raw::Reference->create(
      $refname, $self->store, $self->store->lookup($digest));
}

sub delete_ref {
    my ($self, $refname) = @_;
    Git::Raw::Reference->lookup($refname, $self->store)->delete;
}

1;

__END__

=pod

=for Pod::Coverage
  refs
  _deref
  put_ref
  delete_ref

=head1 NAME

Git::Database::Backend::Git::Raw::Repository - A Git::Database backend based on Git::Raw

=head1 SYNOPSIS

    # get a store
    my $r  = Git::Raw::Repository->open('path/to/some/git/repository');

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads data from a Git repository using the L<Git::Raw>
bindings to the L<libgit2|http://libgit2.github.com> library.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::RefReader>.
L<Git::Database::Role::RefWriter>.

=head1 AUTHOR

Sergey Romanov <sromanov@cpan.org>

=head1 COPYRIGHT

Copyright 2017 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut