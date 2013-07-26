#!perl

# $Id$

#------------------------------------------------------------------------------
# Time the different versions of Iterator::Simple::Lookahead
#------------------------------------------------------------------------------

use Modern::Perl;
use Benchmark qw(:all);
use File::Basename;
use File::Slurp;

use constant COUNT_ITER => 1000;

# collect all library versions
my %test;
for my $file ((grep {/^ISL_.*\.pm$/} read_dir(".")), "../lib/Iterator/Simple/Lookahead.pm") {
	$test{basename($file, ".pm")} = build_test($file);
}

cmpthese( 0, \%test );

#------------------------------------------------------------------------------
# Test package
#------------------------------------------------------------------------------
sub make_iter {
	my($start, $end) = @_;
	return sub { return if $start >= $end; return $start++; };
}

sub run_tests {
	my($package) = @_;
	my($i, $j, $iter, $value);
	
	# simple get
	$iter = $package->new(make_iter(0, COUNT_ITER));
	for ($i = 0; $i < COUNT_ITER; $i++) {
		$value = $iter->next;
		die "$value != $i" unless $i == $value;
	}
	$value = $iter->next;
	die "$value != undef" if defined $value;
	
	# iterator get
	$iter = $package->new(make_iter(0, COUNT_ITER));
	for ($i = 0; $i < COUNT_ITER; $i++) {
		$value = $iter->();
		die "$value != $i" unless $i == $value;
	}
	$value = $iter->();
	die "$value != undef" if defined $value;
	
	# peek
	$iter = $package->new(make_iter(0, COUNT_ITER));
	for ($i = 0; $i < COUNT_ITER; $i++) {
		$value = $iter->peek($i);
		die "$value != $i" unless $i == $value;
	}
	$value = $iter->peek(COUNT_ITER);
	die "$value != undef" if defined $value;
	for ($i = 0; $i < COUNT_ITER; $i++) {
		$value = $iter->next;
		die "$value != $i" unless $i == $value;
	}
	$value = $iter->next;
	die "$value != undef" if defined $value;

	# unget scalar
	$iter = $package->new();
	for ($i = COUNT_ITER-1; $i >= 0; $i--) {
		$iter->unget($i);
	}
	for ($i = 0; $i < COUNT_ITER; $i++) {
		$value = $iter->next;
		die "$value != $i" unless $i == $value;
	}
	$value = $iter->next;
	die "$value != undef" if defined $value;
	
	# unger iterator
	$iter = $package->new();
	for ($i = COUNT_ITER; $i >= 0; $i -= 11) {
		$iter->unget( make_iter( $i-11 >= 0 ? $i-11 : 0, $i) );
	}
	for ($i = 0; $i < COUNT_ITER; $i++) {
		$value = $iter->next;
		die "$value != $i" unless $i == $value;
	}
	$value = $iter->next;
	die "$value != undef" if defined $value;
	
	# unget chained iterators
	my $list_iter = sub {return};
	for ($i = COUNT_ITER; $i >= 0; $i -= 11) {
		my @iters = ( make_iter( $i-11 >= 0 ? $i-11 : 0, $i), $list_iter );
		$list_iter = sub {
			while (1) {
				return unless @iters;
				my $rv = $iters[0]->();
				return $rv if defined $rv;
				shift @iters;
			}
		};
	}
	$iter = $package->new($list_iter);
	for ($i = 0; $i < COUNT_ITER; $i++) {
		$value = $iter->next;
		die "$value != $i" unless $i == $value;
	}
	$value = $iter->next;
	die "$value != undef" if defined $value;
}

#------------------------------------------------------------------------------
# Build test code for each package
#------------------------------------------------------------------------------
sub build_test {
	my($module_file) = @_;
	
	my $package = basename($module_file, ".pm"); $package =~ s/\W/_/g;
	my $module_code = read_file($module_file);
	$module_code =~ s/\bIterator::Simple::Lookahead\b/$package/g;
	
	my $code = "{\n".$module_code."\n}\n".
				"sub test_$package { run_tests('$package'); }\n".
				"\\&test_$package";
	
	my $code_func = eval($code); $@ and die "$code: $@";
	return $code_func;
}
