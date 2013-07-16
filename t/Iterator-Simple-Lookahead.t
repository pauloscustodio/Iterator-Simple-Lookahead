#!perl

# $Id: Stream.t,v 1.2 2010/10/12 21:18:13 Paulo Exp $

use strict;
use warnings;

use Test::More;
use Iterator::Simple 'iter';

use_ok 'Iterator::Simple::Lookahead';

my $s;

#------------------------------------------------------------------------------
sub t_get (@) {
	my $where = "[line ".(caller)[2]."]";
	for (@_) {
		is $s->peek,     $_, "$where peek is ".($_||"undef");
		is $s->next,     $_, "$where next is ".($_||"undef");
		$s->unget($_);
		is $s->(),       $_, "$where ()   is ".($_||"undef");
		$s->unget($_);
		is scalar(<$s>), $_, "$where <>   is ".($_||"undef");
	}
}

sub t_new (@) {
	my $obj;
	isa_ok $obj = Iterator::Simple::Lookahead->new(@_), 'Iterator::Simple::Lookahead';
	return $obj;
}	

sub array_iter {
	my(@d) = @_;
	return sub { shift @d; };
}

#------------------------------------------------------------------------------
# new without arguments
{
	$s = t_new();
	t_get 	undef, undef;
	$s->unget(1..3);
	t_get 	1, 2, 3, undef, undef;
}

#------------------------------------------------------------------------------
# new with arguments
{
	my $n;
	$s = t_new(
			1..3,
			array_iter(4..6),
			iter( [7..9] ),
			sub {
				$n++;
				return array_iter(10..12) if $n == 1;
				return array_iter(13..15) if $n == 2;
				return;
			},
	);
	t_get 	1..3;
	$s->unget(array_iter(0,1));
	t_get 	0,1,4..15, undef, undef;
}

#------------------------------------------------------------------------------
# unget from within the iterator
{
	my @d1 = (4..6);

	$s = t_new(
			sub {
				my $ret = shift @d1; 
				if ($ret && $ret == 5) {
					$s->unget(1..3);
				}
				return $ret;
			},
	);
	t_get 	4, 5, 1, 2, 3, 6, undef, undef;
}

#------------------------------------------------------------------------------
# peek
{
	$s = t_new( array_iter(0..100) );
	for (0..100) {
		is $s->peek($_), $_, "peek $_";
	}
	for (101..111) {
		is $s->peek($_), undef, "peek $_";
	}
	t_get 	0..100, undef, undef;

	eval {$s->peek(-1)}; 
	like $@, qr/negative index/, "croak on negative peek";
}

#------------------------------------------------------------------------------
# stream of []
{
	$s = t_new( [1,1], [2,4], [3,9] );
	for (1..3) {
		is_deeply $s->(), [$_,$_*$_], "next [$_,$_*$_]";
	}
	t_get undef, undef;
}

#------------------------------------------------------------------------------
# subclass of Iterator::Simple::Iterator
{
	$s = t_new( array_iter( 1..10 ) ) | 
		sub {
			return if $_ % 2 != 0;
			return $_ / 2;
		};
	t_get 1..5, undef, undef;
}

done_testing();
