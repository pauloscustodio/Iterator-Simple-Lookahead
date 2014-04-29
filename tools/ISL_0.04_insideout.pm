# $Id: ISL_0.04_insideout.pm,v 1.1 2013/07/26 23:25:07 Paulo Exp $

package Iterator::Simple::Lookahead;

{ # start closure

#------------------------------------------------------------------------------

=head1 NAME

Iterator::Simple::Lookahead - Simple iterator with lookahead and unget

=cut

#------------------------------------------------------------------------------

use 5.008000;
use strict;
use warnings;

use Carp;
use Iterator::Simple qw( is_iterator );

our $VERSION = '0.06';

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use Iterator::Simple::Lookahead;
  my $iter = Iterator::Simple::Lookahead->new( sub {}, @values );
  my $first = $iter->peek();
  my $second = $iter->peek(1);
  my $next = $iter->next; # or $iter->()
  $iter->unget( sub {}, @values );

=head1 DESCRIPTION

This module encapsulates an iterator function. An iterator function returns the
next element in the stream on each call, and returns C<undef> on end of input.

The iterator can return a code reference - this new iterator is inserted at the 
head of the queue.

The object allows the user to C<peek()> the Nth element of the stream without
consuming it, or to get it and remove from the stream.

A list of items can also be pushed back to the stream by C<unget()>, 
to be retrieved in the subsequent C<next()> calls. The next item can also be
retrieved by calling C<$iter-E<gt>()>.

The input list to the constructor and to C<unget()> contains items to be
retrieved on each C<next()> call, or code references to be called to extract the
next item from the stream.

Other types of input can be converted to a code reference by C<iter()> of 
L<Iterator::Simple|Iterator::Simple>.

This module is built on top of L<Iterator::Simple|Iterator::Simple> 
and returns iterators that are compatible with the former, 
i.e. an object of type C<Iterator::Simple::Lookahead> 
can be used as an input to C<iter()>.

=head1 FUNCTIONS

=head2 new

Creates a new object ready to retrieve elements from the given input list. The 
list contains either values to be returned in a subsequent C<next()> call, or
code references to be called to extract the next item from the stream.

Other types of input can be converted to a code reference by C<iter()> of 
L<Iterator::Simple|Iterator::Simple>.

=cut

#------------------------------------------------------------------------------
# Object contains list of computed values and iterator to compute next
# Global attributes indexed by $self
my %QUEUE;		# list of non-iterator values peeked
my %ITERS;		# list of iterators to be evaluated

use base 'Iterator::Simple::Iterator';

sub new {
	my($class, @items) = @_;
	my $self;
	$self = $class->SUPER::new(sub { return $self->next });
	$QUEUE{$self} = [];
	$ITERS{$self} = [];
	$self->unget(@items);
	return $self;
}

#------------------------------------------------------------------------------

=head2 peek

Retrieves the Nth-element at the head of the stream, but keeps it in the 
stream to be retrieved by C<next()>.

Calls the iterator function to compute the items up to the Nth element, returns
C<undef> if the stream is exhausted before reaching N.

As a special case, C<peek()> retrieves the element at the head of the stream,
or C<undef> if the stream is empty.

=cut

#------------------------------------------------------------------------------

sub _is_iter { ref($_[0]) eq 'CODE' || is_iterator($_[0]) }

sub peek {
	my($self, $n) = @_;
	$n ||= 0; croak("negative index $n") if $n < 0;
	
	while (1) {
		# return element if already computed
		return $QUEUE{$self}[$n] if $n < @{$QUEUE{$self}};
	
		# empty list of iterators -> end of input
		return unless @{$ITERS{$self}};
		
		# get first iterator
		my $iter = $ITERS{$self}[0];
		if ( ! defined $iter ) {
			shift @{$ITERS{$self}};			# skip undefined values
		}
		elsif ( _is_iter($iter) ) {
			my $value = $iter->();
			if ( defined($value) ) {
				# allow an iterator to get another
				unshift @{$ITERS{$self}}, $value;
			}
			else {
				shift @{$ITERS{$self}};		# exhausted
			}
		}
		else {
			push @{$QUEUE{$self}}, $iter;	# not iterator
			shift @{$ITERS{$self}};
		}
	}
}	

#------------------------------------------------------------------------------

=head2 next

Retrieves the element at the head of the stream and removes it from the stream.

Returns C<undef> if the stream is empty

=cut

#------------------------------------------------------------------------------

sub next {
	my($self) = @_;
	$self->peek;	# compute head element
	return shift @{$QUEUE{$self}};
}

#------------------------------------------------------------------------------

=head2 unget

Pushes back a list of values and/or iterators to the stream, that will be
retrieved on the subsequent calls to C<next()>.

Can be called from within an iterator, to insert values that will be returned 
before the current call, e.g. calling from the iterator:

  $stream->unget(1..3); return 4;

will result in the values 1,2,3,4 being returned from the stream.

=cut

#------------------------------------------------------------------------------

sub unget {
	my($self, @items) = @_;
	unshift @{$ITERS{$self}}, @items, @{$QUEUE{$self}};
	@{$QUEUE{$self}} = ();
}

#------------------------------------------------------------------------------

=head1 EXPORT

None.

=head1 AUTHOR

Paulo Custodio, C<< <pscust at cpan.org> >>

=head1 BUGS and FEEDBACK

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Iterator-Simple-Lookahead>.  

=head1 ACKNOWLEDGEMENTS

Inspired in L<HOP::Stream|HOP::Stream> and L<Iterator::Simple|Iterator::Simple>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Paulo Custodio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

} # end closure

1;
